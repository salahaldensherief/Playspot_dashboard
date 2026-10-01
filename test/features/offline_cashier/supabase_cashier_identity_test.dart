import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/supabase_cashier_authority_transport.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/supabase_cashier_sync_transport.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_connection_mode.dart';

void main() {
  const actor = '00000000-0000-0000-0000-000000000001';
  const other = '00000000-0000-0000-0000-000000000002';
  const lounge = '10000000-0000-0000-0000-000000000001';
  const device = '20000000-0000-0000-0000-000000000001';
  late SupabaseClient client;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) respond;
  setUp(() {
    requests = [];
    respond = (request) async => http.Response(
      '{"ok":true}',
      200,
      headers: {'content-type': 'application/json'},
    );
    client = SupabaseClient(
      'https://offline-fixture.invalid',
      'public-fixture-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/logout')) return http.Response('', 204);
        requests.add(request);
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
  Future<void> login(
    String id, {
    String token = 'synthetic-access-token',
  }) async {
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': token,
        'refresh_token': 'synthetic-refresh-token',
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

  Future<Map<String, dynamic>> authority(CashierConnectionMode mode) =>
      SupabaseCashierAuthorityTransport(
        client,
        actor,
      ).refresh(loungeId: lounge, deviceId: device, mode: mode);

  for (final mode in CashierConnectionMode.values) {
    test(
      'authority sends exact $mode contract with authenticated client',
      () async {
        await login(actor);
        expect(await authority(mode), {'ok': true});
        expect(requests, hasLength(1));
        expect(requests.single.method, 'POST');
        expect(requests.single.url.path, '/rest/v1/rpc/refresh_cashier_writer');
        expect(jsonDecode(requests.single.body), {
          'p_lounge_id': lounge,
          'p_device_id': device,
          'p_online': mode == CashierConnectionMode.online,
        });
      },
    );
  }
  for (final source in ['authority', 'sync']) {
    Future<Map<String, dynamic>> send() => source == 'authority'
        ? authority(CashierConnectionMode.offline)
        : SupabaseCashierSyncTransport(
            client,
          ).send({'actor_id': actor, 'id': 'operation'});
    test('$source denies an unauthenticated request before HTTP', () async {
      await expectLater(send(), throwsStateError);
      expect(requests, isEmpty);
    });
    test('$source denies another actor before HTTP', () async {
      await login(other);
      await expectLater(send(), throwsStateError);
      expect(requests, isEmpty);
    });
    for (final transition in ['logout', 'other user', 'same user relogin']) {
      test('$source rejects late reply after $transition', () async {
        await login(actor);
        final reply = Completer<http.Response>();
        final started = Completer<void>();
        respond = (_) {
          started.complete();
          return reply.future;
        };
        final pending = expectLater(send(), throwsStateError);
        await started.future;
        if (transition == 'other user') {
          await login(other);
        } else {
          await client.auth.signOut();
          if (transition == 'same user relogin') {
            await login(actor, token: 'new-synthetic-access-token');
          }
        }
        reply.complete(
          http.Response(
            '{"ok":true}',
            200,
            headers: {'content-type': 'application/json'},
          ),
        );
        await pending;
        expect(requests, hasLength(1));
      });
    }
    test(
      '$source permits token refresh within the same identity session',
      () async {
        await login(actor);
        respond = (_) async {
          await login(actor, token: 'renewed-synthetic-access-token');
          return http.Response('{"ok":true}', 200);
        };
        expect(await send(), {'ok': true});
      },
    );
    test('$source rejects a non-object RPC reply', () async {
      await login(actor);
      respond = (_) async => http.Response('[]', 200);
      await expectLater(send(), throwsFormatException);
    });
  }
}
