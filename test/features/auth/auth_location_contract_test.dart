import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/auth/data/data_source/auth_remote_data_source.dart';

void main() {
  const actor = '00000000-0000-0000-0000-000000000001';
  const other = '00000000-0000-0000-0000-000000000002';
  late SupabaseClient client;
  late List<http.Request> calls;
  late Future<http.Response> Function(http.Request) respond;
  http.Response json(Object data, [int status = 200]) => http.Response(
    jsonEncode(data),
    status,
    headers: {'content-type': 'application/json'},
  );
  setUp(() {
    calls = [];
    respond = (request) async {
      if (request.url.path.contains('/functions/')) {
        return json({'success': true});
      }
      if (request.url.path.endsWith('/platform_super_admins')) return json([]);
      if (request.url.path.endsWith('/get_my_profile')) {
        return json({'id': actor, 'role': 'owner'});
      }
      if (request.method == 'PATCH') return json({'id': actor});
      throw StateError('Unexpected request ${request.url}');
    };
    client = SupabaseClient(
      'https://fixture.invalid',
      'public-fixture-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/logout')) return http.Response('', 204);
        calls.add(request);
        final result = await respond(request);
        return http.Response.bytes(
          result.bodyBytes,
          result.statusCode,
          headers: result.headers,
          request: request,
        );
      }),
    );
  });
  tearDown(() => client.dispose());
  Future<void> login([String id = actor]) => client.auth.recoverSession(
    jsonEncode({
      'access_token': 'synthetic-access-token',
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
  Future<void> update({double latitude = 31, double longitude = 30}) async {
    await AuthRemoteDataSourceImpl(
      client,
    ).updateUserLocation(latitude: latitude, longitude: longitude);
  }

  test(
    'current profile cannot be requested using another account identity',
    () async {
      await login();
      expect(
        await AuthRemoteDataSourceImpl(client).getCurrentUser(userId: other),
        isNull,
      );
      expect(calls, isEmpty);
    },
  );
  test(
    'foreign profile response cannot become the authenticated user',
    () async {
      await login();
      respond = (request) async =>
          request.url.path.endsWith('/platform_super_admins')
          ? json([])
          : json({'id': other, 'role': 'super_admin'});
      expect(await AuthRemoteDataSourceImpl(client).getCurrentUser(), isNull);
    },
  );
  test(
    'profile request failure preserves the session and can be retried',
    () async {
      await login();
      var fail = true;
      respond = (request) async {
        if (request.url.path.endsWith('/platform_super_admins'))
          return json([]);
        if (fail)
          return json({'message': 'synthetic denied', 'code': '42501'}, 403);
        return json({'id': actor, 'role': 'owner'});
      };
      final source = AuthRemoteDataSourceImpl(client);
      await expectLater(
        source.getCurrentUser(),
        throwsA(isA<PostgrestException>()),
      );
      expect(client.auth.currentUser?.id, actor);
      fail = false;
      expect((await source.getCurrentUser())?.id, actor);
    },
  );
  for (final eligible in [true, false]) {
    test(
      'platform membership only promotes an eligible profile: $eligible',
      () async {
        await login();
        respond = (request) async =>
            request.url.path.endsWith('/platform_super_admins')
            ? json([
                {'user_id': actor},
              ])
            : json({
                'id': actor,
                'role': 'owner',
                'is_active': eligible,
                'is_banned': !eligible,
              });
        final user = await AuthRemoteDataSourceImpl(client).getCurrentUser();
        expect(user, isNotNull);
        expect(user!.isSuperAdmin, eligible);
      },
    );
  }
  test(
    'location uses configured client API key and authenticated function headers',
    () async {
      await login();
      await update();
      final function = calls.first;
      expect(function.url.path, '/functions/v1/update-user-location');
      expect(function.headers['apikey'], 'public-fixture-key');
      expect(
        function.headers['authorization'],
        'Bearer synthetic-access-token',
      );
      expect(jsonDecode(function.body), {'latitude': 31.0, 'longitude': 30.0});
      expect(calls.where((r) => r.method == 'PATCH'), isEmpty);
    },
  );
  for (final status in [400, 401, 403, 422]) {
    test(
      '$status location rejection cannot trigger direct profile update',
      () async {
        await login();
        respond = (_) async => json({'error': 'rejected'}, status);
        await expectLater(update(), throwsA(isA<FunctionException>()));
        expect(calls, hasLength(1));
      },
    );
  }
  test(
    'city service outage saves only caller coordinates, preserving city',
    () async {
      await login();
      final success = respond;
      respond = (request) => request.url.path.contains('/functions/')
          ? Future.value(json({'error': 'geocoder unavailable'}, 502))
          : success(request);
      await update();
      final saved = calls.singleWhere((r) => r.method == 'PATCH');
      final body = jsonDecode(saved.body) as Map;
      expect(body.keys.toSet(), {'latitude', 'longitude', 'updated_at'});
      expect(saved.url.queryParameters['id'], 'eq.$actor');
      expect(saved.url.queryParameters['select'], 'id');
    },
  );
  test(
    'denied fallback save is an error instead of fabricated success',
    () async {
      await login();
      respond = (request) async => request.url.path.contains('/functions/')
          ? json({'error': 'unavailable'}, 502)
          : json({'code': '42501', 'message': 'denied'}, 403);
      await expectLater(update(), throwsA(isA<PostgrestException>()));
      expect(calls.map((r) => r.method), ['POST', 'PATCH']);
    },
  );
  test(
    'account switch during city lookup cannot write either profile',
    () async {
      await login();
      final pending = Completer<http.Response>();
      respond = (_) => pending.future;
      final updating = update();
      await Future<void>.delayed(Duration.zero);
      await login(other);
      pending.complete(json({'error': 'unavailable'}, 502));
      await expectLater(updating, throwsA(isA<AuthException>()));
      expect(calls, hasLength(1));
    },
  );
  test('invalid coordinate cannot invoke network or save profile', () async {
    await login();
    await expectLater(update(latitude: double.nan), throwsArgumentError);
    await expectLater(update(longitude: 181), throwsArgumentError);
    expect(calls, isEmpty);
  });
  test('unauthenticated location update is rejected before network', () async {
    await expectLater(update(), throwsA(isA<AuthException>()));
    expect(calls, isEmpty);
  });
}
