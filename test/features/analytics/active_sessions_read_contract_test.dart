import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/analytics/data/datasources/active_sessions_stream_helper.dart';

void main() {
  late SupabaseClient client;
  late List<http.Request> requests;
  var rpcDenied = false;
  var profileDenied = false;
  var includeProfile = true;
  setUp(() {
    requests = [];
    rpcDenied = profileDenied = false;
    includeProfile = true;
    client = SupabaseClient(
      'https://fixture.invalid',
      'fixture-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        final denied =
            (path.contains('/rpc/') && rpcDenied) ||
            (path.endsWith('/profiles') && profileDenied);
        final rows = path.endsWith('/profiles')
            ? (includeProfile
                  ? [
                      {
                        'id': 'user-1',
                        'full_name': 'Customer',
                        'phone': 'fixture-phone',
                      },
                    ]
                  : [])
            : [
                {
                  'id': 'booking-1',
                  'user_id': 'user-1',
                  'status': 'in_progress',
                  if (!includeProfile) 'user_name': 'Walk-in',
                  'rooms': {'name': 'Room 1'},
                  'canteen_orders': [
                    {
                      'id': 'order-1',
                      'total_price': 20,
                      'canteen_order_items': [
                        {
                          'id': 'item-1',
                          'quantity': 2,
                          'unit_price': 10,
                          'total_price': 20,
                        },
                      ],
                    },
                  ],
                },
              ];
        return http.Response(
          jsonEncode(denied ? {'code': '42501', 'message': 'denied'} : rows),
          denied ? 403 : 200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
  });
  tearDown(() => client.dispose());
  test(
    'global active-session read batches visible profiles and preserves orders',
    () async {
      final bookings = await ActiveSessionsStreamHelper(
        client,
      ).fetchActiveSessions();
      expect(bookings.single.userName, 'Customer');
      expect(bookings.single.canteenOrders, hasLength(1));
      final select = requests.first.url.queryParameters['select']!;
      expect(select.contains('profiles('), isFalse);
      expect(select.contains('extras(id,name,name_ar,name_en,price)'), isTrue);
      expect(requests.first.url.queryParameters['status'], 'eq.in_progress');
      expect(requests.last.url.path, '/rest/v1/profiles');
      expect(requests.last.url.queryParameters['id'], 'in.("user-1")');
    },
  );
  test(
    'scoped RPC denial remains visible without weaker table fallback',
    () async {
      rpcDenied = true;
      await expectLater(
        ActiveSessionsStreamHelper(
          client,
        ).fetchActiveSessions(loungeId: 'venue'),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests, hasLength(1));
      expect(jsonDecode(requests.single.body), {'p_lounge_id': 'venue'});
    },
  );
  test(
    'missing visible profile keeps walk-in identity instead of inventing a customer',
    () async {
      includeProfile = false;
      expect(
        (await ActiveSessionsStreamHelper(
          client,
        ).fetchActiveSessions()).single.userName,
        'Walk-in',
      );
    },
  );
  test(
    'failed enrichment does not silently emit sessions without requested details',
    () async {
      profileDenied = true;
      await expectLater(
        ActiveSessionsStreamHelper(client).fetchActiveSessions(),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests, hasLength(2));
    },
  );
}
