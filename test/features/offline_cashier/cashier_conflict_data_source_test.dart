import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_conflict_data_source.dart';

void main() {
  const actor = '00000000-0000-0000-0000-000000000001';
  const lounge = '10000000-0000-0000-0000-000000000001';

  late SupabaseClient client;
  late Future<http.Response> Function(http.Request) respond;

  setUp(() {
    respond = (request) async => http.Response(
      jsonEncode({'ok': true}),
      200,
      headers: {'content-type': 'application/json'},
    );
    client = SupabaseClient(
      'https://offline-fixture.invalid',
      'public-fixture-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/logout')) return http.Response('', 204);
        final response = await respond(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
  });

  tearDown(() => client.dispose());

  Future<void> login(String id) async {
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': 'synthetic-token',
        'refresh_token': 'synthetic-refresh',
        'token_type': 'bearer',
        'user': {
          'id': id,
          'aud': 'authenticated',
          'app_metadata': {},
          'user_metadata': {},
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
  }

  test('load parses valid conflict records correctly', () async {
    await login(actor);
    respond = (request) async {
      expect(request.url.path, '/rest/v1/rpc/get_cashier_sync_conflicts');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['p_lounge_id'], lounge);
      return http.Response(
        jsonEncode([
          {
            'operation_id': 'op-1',
            'booking_id': 'book-1',
            'actor_id': actor,
            'kind': 'reserve',
            'code': 'ROOM_CONFLICT',
            'sequence': 1,
            'retry_pending': false,
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    };

    final dataSource = CashierConflictDataSource(client);
    final results = await dataSource.load(actor, lounge);

    expect(results, hasLength(1));
    expect(results.first.operationId, 'op-1');
    expect(results.first.bookingId, 'book-1');
    expect(results.first.actorId, actor);
    expect(results.first.kind, 'reserve');
    expect(results.first.code, 'ROOM_CONFLICT');
    expect(results.first.sequence, 1);
    expect(results.first.retryPending, isFalse);
  });

  test('load throws FormatException on invalid conflict shape', () async {
    await login(actor);
    respond = (request) async {
      return http.Response(
        jsonEncode([
          {
            'operation_id': 'op-1',
            // Missing sequence, actor_id, etc.
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    };

    final dataSource = CashierConflictDataSource(client);
    expect(dataSource.load(actor, lounge), throwsFormatException);
  });

  test('approve completes when server returns approved receipt', () async {
    await login(actor);
    respond = (request) async {
      expect(request.url.path, '/rest/v1/rpc/approve_cashier_conflict_retry');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['p_lounge_id'], lounge);
      expect(body['p_operation_id'], 'op-1');
      expect(body['p_review_id'], 'rev-1');
      expect(body['p_reason'], 'Corrected room double-booking');
      return http.Response(
        jsonEncode({
          'lounge_id': lounge,
          'operation_id': 'op-1',
          'review_id': 'rev-1',
          'status': 'approved',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    };

    final dataSource = CashierConflictDataSource(client);
    await expectLater(
      dataSource.approve(
        actorId: actor,
        loungeId: lounge,
        operationId: 'op-1',
        reviewId: 'rev-1',
        reason: 'Corrected room double-booking',
      ),
      completes,
    );
  });

  test(
    'approve throws FormatException when receipt status is not approved',
    () async {
      await login(actor);
      respond = (request) async {
        return http.Response(
          jsonEncode({
            'lounge_id': lounge,
            'operation_id': 'op-1',
            'review_id': 'rev-1',
            'status': 'rejected',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      };

      final dataSource = CashierConflictDataSource(client);
      expect(
        dataSource.approve(
          actorId: actor,
          loungeId: lounge,
          operationId: 'op-1',
          reviewId: 'rev-1',
          reason: 'Corrected room double-booking',
        ),
        throwsFormatException,
      );
    },
  );
}
