import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source_impl.dart';

void main() {
  for (final code in ['42501', '28000', 'PGRST202', '42883']) {
    test(
      'booking RPC error $code never falls back to direct table reads',
      () async {
        final calls = <http.Request>[];
        final client = SupabaseClient(
          'https://fixture.invalid',
          'fixture-public',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
            calls.add(request);
            return http.Response(
              jsonEncode({'code': code, 'message': 'denied or unavailable'}),
              code == '42501' ? 403 : 400,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }),
        );
        addTearDown(client.dispose);
        await expectLater(
          BookingRemoteDataSourceImpl(client).getBookings(loungeId: 'branch-b'),
          throwsA(isA<PostgrestException>()),
        );
        expect(calls, hasLength(1));
        expect(calls.single.url.path, '/rest/v1/rpc/get_all_bookings_admin');
        expect(jsonDecode(calls.single.body)['p_lounge_id'], 'branch-b');
      },
    );
  }
  test(
    'empty authorized result remains empty without reading a wider scope',
    () async {
      final calls = <http.Request>[];
      final client = SupabaseClient(
        'https://fixture.invalid',
        'fixture-public',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          calls.add(request);
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      expect(await BookingRemoteDataSourceImpl(client).getBookings(), isEmpty);
      expect(calls, hasLength(1));
    },
  );
}
