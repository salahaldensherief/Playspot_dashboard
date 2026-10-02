import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_auth_request.dart';

void main() {
  test(
    'same actor sign-in discards a previous authenticated HTTP result',
    () async {
      const actorId = '00000000-0000-0000-0000-000000000001';
      Map<String, dynamic> session(String token) => {
        'access_token': token,
        'refresh_token': 'synthetic-refresh',
        'token_type': 'bearer',
        'user': {
          'id': actorId,
          'aud': 'authenticated',
          'app_metadata': {},
          'user_metadata': {},
          'created_at': '2026-01-01T00:00:00Z',
        },
      };
      final client = SupabaseClient(
        'https://auth-fixture.invalid',
        'public-fixture-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode(session('replacement-token')),
            200,
            request: request,
          ),
        ),
      );
      addTearDown(client.dispose);
      await client.auth.recoverSession(jsonEncode(session('original-token')));
      final pending = Completer<String>();
      final started = Completer<void>();
      final result = expectLater(
        CashierAuthRequest.run(client, actorId, () {
          started.complete();
          return pending.future;
        }),
        throwsStateError,
      );
      await started.future;
      await client.auth.signInWithPassword(
        email: 'fixture@example.invalid',
        password: 'synthetic-password',
      );
      expect(client.auth.currentUser?.id, actorId);
      pending.complete('late-result');
      await result;
    },
  );
}
