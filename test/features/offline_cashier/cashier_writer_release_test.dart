import 'dart:async';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_lifecycle_gate.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_authority_refresher.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_authority_transport.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_connection_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_writer_releaser.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_writer_release_transport.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_bootstrap_store.dart';
import 'support/authority_harness.dart';

class _Transport implements CashierWriterReleaseTransport {
  final started = Completer<void>();
  final result = Completer<Map<String, dynamic>>();
  final requests = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> release(Map<String, dynamic> request) {
    requests.add(Map.of(request));
    if (!started.isCompleted) started.complete();
    return result.future;
  }
}

class _Renewal implements CashierAuthorityTransport {
  final started = Completer<void>();
  final result = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> refresh({
    required String loungeId,
    required String deviceId,
    required CashierConnectionMode mode,
  }) {
    started.complete();
    return result.future;
  }
}

void main() {
  late AuthorityHarness h;
  late _Transport transport;
  late CashierWriterReleaser service;
  setUp(() async {
    h = AuthorityHarness();
    await h.open();
    await h.install(h.previous);
    transport = _Transport();
    service = CashierWriterReleaser(journal: h.journal, transport: transport);
  });
  tearDown(() => h.dispose());
  Map<String, dynamic> receipt() => {
    'protocol_version': 2,
    'released': true,
    'actor_id': h.journal.actorId,
    'lounge_id': h.journal.loungeId,
    'device_id': h.deviceId,
    'permit_id': h.previous['permit_id'],
    'last_applied_sequence': h.previous['last_applied_sequence'],
    'released_at': h.now.toIso8601String(),
  };

  test('durable barrier exists before HTTP and prevents bootstrap', () async {
    final pending = service.release();
    await transport.started.future;
    final state = await h.journal.read();
    expect(state['writer_release']['status'], 'pending');
    expect(transport.requests.single, {
      'p_lounge_id': h.journal.loungeId,
      'p_device_id': h.deviceId,
      'p_permit_id': h.previous['permit_id'],
      'p_last_applied_sequence': h.previous['last_applied_sequence'],
    });
    await expectLater(
      CashierBootstrapStore(h.store).prepare(),
      throwsStateError,
    );
    transport.result.complete(receipt());
    await pending;
  });
  for (final barrier in [
    'outbox',
    'sync_conflicts',
    'authority_review_required',
  ]) {
    test('refuses $barrier before sending release', () async {
      await h.journal.mutate((state) {
        state[barrier] = switch (barrier) {
          'outbox' => [h.pending],
          'sync_conflicts' => {
            'saved': {'code': 'ROOM_CONFLICT'},
          },
          _ => true,
        };
      });
      await expectLater(service.release(), throwsStateError);
      expect(transport.requests, isEmpty);
      expect((await h.journal.read())['writer_release'], isNull);
    });
  }
  test(
    'uncertain response stays frozen across Hive reopen and exact retry',
    () async {
      final pending = service.release();
      final failed = expectLater(pending, throwsA(isA<TimeoutException>()));
      await transport.started.future;
      transport.result.completeError(TimeoutException('Response lost'));
      await failed;
      final original = transport.requests.single;
      await h.journal.close();
      await h.reopen();
      expect((await h.journal.read())['writer_release']['status'], 'pending');
      final retry = _Transport();
      final newService = CashierWriterReleaser(
        journal: h.journal,
        transport: retry,
      );
      final future = newService.release();
      await retry.started.future;
      expect(retry.requests.single, original);
      retry.result.complete(receipt());
      await future;
      expect((await h.journal.read())['writer_release']['status'], 'released');
    },
  );
  test(
    'repeated taps share one request and confirmed retries use the receipt',
    () async {
      final a = service.release(), b = service.release();
      await transport.started.future;
      expect(transport.requests.length, 1);
      transport.result.complete(receipt());
      expect(await a, await b);
      expect(await service.release(), receipt());
      expect(transport.requests.length, 1);
    },
  );
  for (final field in [
    'protocol_version',
    'released',
    'actor_id',
    'lounge_id',
    'device_id',
    'permit_id',
    'last_applied_sequence',
    'released_at',
  ]) {
    test('invalid $field receipt preserves the paused device', () async {
      final future = service.release();
      final failed = expectLater(future, throwsFormatException);
      await transport.started.future;
      transport.result.complete(receipt()..[field] = null);
      await failed;
      expect((await h.journal.read())['writer_release']['status'], 'pending');
    });
  }
  test('retired permit refresh cannot erase the release barrier', () async {
    final pending = service.release();
    await transport.started.future;
    transport.result.complete(receipt());
    await pending;
    await expectLater(h.install(h.previous), throwsStateError);
    await expectLater(h.install(h.current), throwsStateError);
    expect((await h.journal.read())['writer_release']['status'], 'released');
  });
  test(
    'logout during release ignores late receipt without unfreezing data',
    () async {
      var active = true;
      service = CashierWriterReleaser(
        journal: h.journal,
        transport: transport,
        ensureActive: () {
          if (!active) throw StateError('offline_cashier.permission_denied');
        },
      );
      final future = service.release();
      final failed = expectLater(future, throwsStateError);
      await transport.started.future;
      active = false;
      transport.result.complete(receipt());
      await failed;
      expect((await h.journal.read())['writer_release']['status'], 'pending');
    },
  );
  test(
    'release waits for in-flight renewal and freezes its new permit',
    () async {
      final gate = CashierLifecycleGate();
      final renewal = _Renewal();
      final refresher = CashierAuthorityRefresher(
        store: h.store,
        transport: renewal,
        lifecycle: gate,
      );
      service = CashierWriterReleaser(
        journal: h.journal,
        transport: transport,
        lifecycle: gate,
      );
      final refreshing = refresher.refresh(
        deviceId: h.deviceId,
        mode: CashierConnectionMode.offline,
      );
      await renewal.started.future;
      final releasing = service.release();
      await Future<void>.delayed(Duration.zero);
      expect(transport.requests, isEmpty);
      expect((await h.journal.read())['writer_release'], isNull);
      h.now = DateTime.fromMillisecondsSinceEpoch(
        h.current['server_time_ms'],
        isUtc: true,
      );
      renewal.result.complete(h.current);
      await refreshing;
      await transport.started.future;
      expect(transport.requests.single['p_permit_id'], h.current['permit_id']);
      transport.result.complete(
        receipt()
          ..['permit_id'] = h.current['permit_id']
          ..['last_applied_sequence'] = h.current['last_applied_sequence'],
      );
      await releasing;
      await expectLater(
        refresher.refresh(
          deviceId: h.deviceId,
          mode: CashierConnectionMode.offline,
        ),
        throwsStateError,
      );
    },
  );
}
