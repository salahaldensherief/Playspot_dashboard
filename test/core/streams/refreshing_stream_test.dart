import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/core/streams/refreshing_stream.dart';

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  test(
    'bursts during an initial fetch produce one serialized follow-up',
    () async {
      final events = StreamController<Object?>(sync: true);
      final requests = <Completer<int>>[];
      final received = <int>[];
      final subscription = refreshingStream<int>(
        fetch: () {
          final request = Completer<int>();
          requests.add(request);
          return request.future;
        },
        invalidations: () => events.stream,
        debounce: Duration.zero,
      ).listen(received.add);
      expect(requests, hasLength(1));
      events.add(null);
      events.add(null);
      await _flush();
      expect(requests, hasLength(1));
      requests.first.complete(1);
      await _flush();
      expect(requests, hasLength(2));
      requests.last.complete(2);
      await _flush();
      expect(received, [1, 2]);
      expect(requests, hasLength(2));
      await subscription.cancel();
      await events.close();
    },
  );

  test('cancel stops resources and ignores an in-flight response', () async {
    var calls = 0;
    var cancelled = false;
    final result = Completer<int>();
    final events = StreamController<Object?>(onCancel: () => cancelled = true);
    final received = <int>[];
    final subscription = refreshingStream<int>(
      fetch: () {
        calls++;
        return result.future;
      },
      invalidations: () => events.stream,
      debounce: Duration.zero,
      pollInterval: const Duration(milliseconds: 20),
    ).listen(received.add);
    await subscription.cancel();
    expect(cancelled, isTrue);
    result.complete(1);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(received, isEmpty);
    expect(calls, 1);
    await events.close();
  });

  test(
    'pause stops polling, resume fetches fresh data, errors recover',
    () async {
      var calls = 0;
      final events = StreamController<Object?>(sync: true);
      final received = <int>[];
      final errors = <Object>[];
      final subscription = refreshingStream<int>(
        fetch: () async {
          calls++;
          if (calls == 1) throw StateError('fixture');
          return calls;
        },
        invalidations: () => events.stream,
        debounce: Duration.zero,
        pollInterval: const Duration(seconds: 30),
      ).listen(received.add, onError: errors.add);
      await _flush();
      expect(errors, hasLength(1));
      subscription.pause();
      events.add(null);
      await _flush();
      expect(calls, 1);
      subscription.resume();
      await _flush();
      expect(received, [2]);
      await subscription.cancel();
      await events.close();
    },
  );

  test('polling remains available when realtime setup fails', () async {
    var calls = 0;
    final firstRefresh = Completer<void>();
    final subscription =
        refreshingStream<int>(
          fetch: () async => ++calls,
          invalidations: () => throw StateError('offline realtime'),
          debounce: Duration.zero,
          pollInterval: const Duration(milliseconds: 20),
        ).listen((value) {
          if (value >= 2 && !firstRefresh.isCompleted) firstRefresh.complete();
        });
    await firstRefresh.future.timeout(const Duration(seconds: 2));
    await subscription.cancel();
    final cancelledCalls = calls;
    await _flush();
    expect(calls, cancelledCalls);
  });
}
