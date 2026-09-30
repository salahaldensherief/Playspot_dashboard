import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/onboarding/data/datasources/onboarding_remote_data_source_impl.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';

void main() {
  late List<http.Request> requests;
  late SupabaseClient client;
  late OnboardingRemoteDataSourceImpl source;
  var rpcStatus = 200;
  var readStatus = 200;
  setUp(() {
    requests = [];
    rpcStatus = 200;
    readStatus = 200;
    client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final rpc = request.url.path.contains('/rpc/');
        final status = rpc ? rpcStatus : readStatus;
        final body = status != 200
            ? {'code': '42501', 'message': 'denied'}
            : rpc
            ? request.url.path.endsWith('/onboard_lounge')
                  ? {
                      'success': true,
                      'lounge_id': 'lounge-1',
                      'status': 'pending',
                    }
                  : null
            : {
                'id': 'lounge-1',
                'name': 'Test lounge',
                'image_url': '',
                'opening_time': '10:00:00',
                'closing_time': '02:00:00',
                'status': 'pending',
                'is_active': false,
                'is_open': false,
              };
        return http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    source = OnboardingRemoteDataSourceImpl(client);
  });
  tearDown(() async => client.dispose());

  Future<dynamic> submit() => source.batchCompleteOnboarding(
    loungeId: 'lounge-1',
    loungeData: {'name': 'Test lounge'},
    rooms: [
      {'name': 'Room 1'},
    ],
    extras: [
      {'name': 'Water'},
    ],
  );

  test(
    'void RPC success fetches the lounge without replaying mutations',
    () async {
      final lounge = await submit();
      expect(lounge.id, 'lounge-1');
      expect(lounge.status, 'pending');
      expect(requests.map((r) => r.method), ['POST', 'GET']);
      expect(requests.first.url.path, '/rest/v1/rpc/batch_complete_onboarding');
      expect(jsonDecode(requests.first.body), {
        'p_lounge_id': 'lounge-1',
        'p_lounge_data': {'name': 'Test lounge'},
        'p_rooms': [
          {'name': 'Room 1'},
        ],
        'p_extras': [
          {'name': 'Water'},
        ],
      });
      expect(requests.last.url.path, '/rest/v1/lounges');
      expect(requests.last.url.queryParameters['id'], 'eq.lounge-1');
    },
  );

  test('RPC denial is propagated without direct table fallback', () async {
    rpcStatus = 403;
    await expectLater(submit(), throwsA(isA<PostgrestException>()));
    expect(requests, hasLength(1));
  });

  test(
    'read failure after commit never replays rooms or marks profile complete',
    () async {
      readStatus = 403;
      await expectLater(submit(), throwsA(isA<PostgrestException>()));
      expect(requests.map((r) => r.method), ['POST', 'GET']);
    },
  );

  test(
    'setup reads the returned lounge ID rather than parsing RPC metadata as entity',
    () async {
      final lounge = await source.setupLounge(
        const Lounge(
          id: '',
          name: 'Test lounge',
          imageUrl: '',
          opensAt: '10:00',
          closesAt: '02:00',
        ),
      );
      expect(lounge.id, 'lounge-1');
      expect(lounge.name, 'Test lounge');
      expect(lounge.status, 'pending');
      expect(requests, hasLength(2));
      expect(requests.first.url.path, '/rest/v1/rpc/onboard_lounge');
      final payload = jsonDecode(requests.first.body);
      expect(payload['p_opens_at'], '10:00:00');
      expect(payload['p_closes_at'], '02:00:00');
    },
  );
}
