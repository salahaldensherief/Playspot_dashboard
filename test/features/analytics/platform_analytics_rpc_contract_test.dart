import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source_impl.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/lounges/data/datasources/lounge_analytics_remote_helper.dart';

void main() {
  for (final period in ['day', 'week', 'month']) {
    test(
      'revenue contract uses p_period=$period and maps the period label',
      () async {
        final calls = <http.Request>[];
        final client = SupabaseClient(
          'https://example.invalid',
          'fixture-key',
          httpClient: MockClient((request) async {
            calls.add(request);
            return http.Response(
              jsonEncode([
                {'period': '2026-10-03T00:00:00', 'revenue': 125},
              ]),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }),
        );
        addTearDown(client.dispose);
        final rows = await LoungeAnalyticsRemoteHelper(
          client,
        ).getRevenueOverTime(period);
        expect(calls.single.url.path, endsWith('/rpc/get_revenue_over_time'));
        expect(jsonDecode(calls.single.body), {'p_period': period});
        expect(rows.single['day'], '2026-10-03T00:00:00');
        expect(rows.single['revenue'], 125);
      },
    );
  }

  test(
    'owner statistics denial never falls back to a global overview or zeros',
    () async {
      final calls = <http.Request>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'fixture-key',
        httpClient: MockClient((request) async {
          calls.add(request);
          return http.Response(
            jsonEncode({'code': '42501', 'message': 'Not authorized'}),
            403,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      await expectLater(
        LoungeAnalyticsRemoteHelper(client).getDashboardStats('lounge'),
        throwsA(isA<PostgrestException>()),
      );
      expect(calls, hasLength(1));
      expect(jsonDecode(calls.single.body), {'p_lounge_id': 'lounge'});
    },
  );
  for (final response in [
    null,
    <String, dynamic>{},
    {'valid': false},
    {'valid': true},
  ]) {
    test('voucher contract fails closed for $response', () async {
      final client = SupabaseClient(
        'https://example.invalid',
        'fixture-key',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode(response),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(client.dispose);
      final call = BookingRemoteDataSourceImpl(
        client,
      ).validateVoucherByCode('CODE');
      if (response != null && response['valid'] == true) {
        expect(await call, {'valid': true});
      } else {
        await expectLater(call, throwsA(isA<Exception>()));
      }
    });
  }
}
