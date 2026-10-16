import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/tournaments/data/datasources/tournament_match_remote_helper.dart';

class _Channel extends Fake implements RealtimeChannel {
  _Channel(this.name);
  final String name;
  late void Function(PostgresChangePayload) callback;
  @override
  RealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    String? schema,
    String? table,
    PostgresChangeFilter? filter,
    List<PostgresChangeFilter>? filters,
    List<String>? select,
    required void Function(PostgresChangePayload) callback,
  }) {
    this.callback = callback;
    return this;
  }

  @override
  RealtimeChannel subscribe([
    void Function(RealtimeSubscribeStatus, Object?)? callback,
    Duration? timeout,
  ]) => this;
}

class _Client extends SupabaseClient {
  _Client(http.Client httpClient)
    : super('https://fixture.invalid', 'fixture-key', httpClient: httpClient);
  final created = <_Channel>[];
  final removed = <RealtimeChannel>[];
  @override
  RealtimeChannel channel(
    String name, {
    RealtimeChannelConfig opts = const RealtimeChannelConfig(),
  }) {
    final channel = _Channel(name);
    created.add(channel);
    return channel;
  }

  @override
  Future<String> removeChannel(RealtimeChannel channel) async {
    removed.add(channel);
    return 'ok';
  }
}

void main() {
  late _Client client;
  late TournamentMatchRemoteHelper helper;
  var disputed = true;
  var denied = false;
  setUp(() {
    disputed = true;
    denied = false;
    client = _Client(
      MockClient(
        (request) async => http.Response(
          jsonEncode(
            denied
                ? {'code': '42501', 'message': 'denied'}
                : [
                    {
                      'id': 'match-1',
                      'tournament_id': 't-1',
                      'status': disputed ? 'disputed' : 'completed',
                    },
                  ],
          ),
          denied ? 403 : 200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );
    helper = TournamentMatchRemoteHelper(client);
  });
  tearDown(() async {
    helper.dispose();
    await client.dispose();
  });
  test(
    'independent consumers keep their own channels and cancellation scope',
    () async {
      final first = helper.watchDisputedMatches('t-1').listen((_) {});
      final second = helper.watchDisputedMatches('t-1').listen((_) {});
      expect(client.removed, isEmpty);
      expect(client.created.map((c) => c.name).toSet(), hasLength(2));
      await first.cancel();
      expect(client.removed, [client.created.first]);
      await second.cancel();
      expect(client.removed, [client.created.first, client.created.last]);
    },
  );
  test(
    'resolution refreshes disputes when oldRecord contains only the primary key',
    () async {
      final initial = Completer<void>();
      final cleared = Completer<void>();
      final subscription = helper.watchDisputedMatches('t-1').listen((matches) {
        if (matches.isNotEmpty && !initial.isCompleted) initial.complete();
        if (matches.isEmpty && !cleared.isCompleted) cleared.complete();
      });
      await initial.future;
      disputed = false;
      client.created.single.callback(
        PostgresChangePayload(
          schema: 'public',
          table: 'tournament_matches',
          commitTimestamp: DateTime.now(),
          eventType: PostgresChangeEvent.update,
          newRecord: {'id': 'match-1', 'status': 'completed'},
          oldRecord: {'id': 'match-1'},
          errors: null,
        ),
      );
      await expectLater(
        cleared.future.timeout(const Duration(milliseconds: 300)),
        completes,
      );
      await subscription.cancel();
    },
  );
  test(
    'a realtime refresh failure reaches the consumer instead of stale success',
    () async {
      final initial = Completer<void>();
      final error = Completer<Object>();
      final subscription = helper
          .watchDisputedMatches('t-1')
          .listen(
            (_) {
              if (!initial.isCompleted) initial.complete();
            },
            onError: (Object e) {
              if (!error.isCompleted) error.complete(e);
            },
          );
      await initial.future;
      denied = true;
      client.created.single.callback(
        PostgresChangePayload(
          schema: 'public',
          table: 'tournament_matches',
          commitTimestamp: DateTime.now(),
          eventType: PostgresChangeEvent.update,
          newRecord: {'id': 'match-1', 'status': 'disputed'},
          oldRecord: {'id': 'match-1'},
          errors: null,
        ),
      );
      await expectLater(
        error.future.timeout(const Duration(milliseconds: 300)),
        completion(isA<PostgrestException>()),
      );
      await subscription.cancel();
    },
  );
}
