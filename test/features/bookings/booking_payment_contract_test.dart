import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source_impl.dart';

void main() {
  test('booking approval changes status without collecting payment', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          'null',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );

    final source = BookingRemoteDataSourceImpl(client);

    await source.approveBooking('booking-approve');

    expect(requests, hasLength(1));
    expect(
      requests.single.url.path,
      '/rest/v1/rpc/update_booking_status_admin',
    );

    final payload = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(payload['p_booking_id'], 'booking-approve');
    expect(payload['p_status'], 'upcoming');
    expect(payload.containsKey('payment_status'), isFalse);
    expect(payload.containsKey('p_payment_method'), isFalse);

    await client.dispose();
  });

  test('cash payment uses the canonical complete_booking_payment RPC', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          'null',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );

    final source = BookingRemoteDataSourceImpl(client);

    await source.confirmCashPayment('booking-a');

    expect(requests, hasLength(1));
    expect(
      requests.single.url.path,
      '/rest/v1/rpc/complete_booking_payment',
    );

    final payload = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(payload['p_booking_id'], 'booking-a');
    expect(payload['p_payment_method'], 'cash');
    expect(payload.containsKey('p_shift_id'), isFalse);
    expect(payload.containsKey('p_discount_amount'), isFalse);

    await client.dispose();
  });

  test('discount is approved before payment collection', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          'null',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );

    final source = BookingRemoteDataSourceImpl(client);

    await source.confirmCashPayment(
      'booking-b',
      discountAmount: 25,
      discountPercentage: 0,
      discountReason: 'Manager-approved compensation',
    );

    expect(requests, hasLength(2));
    expect(
      requests[0].url.path,
      '/rest/v1/rpc/apply_booking_discount',
    );
    expect(
      requests[1].url.path,
      '/rest/v1/rpc/complete_booking_payment',
    );

    final discountPayload =
        jsonDecode(requests[0].body) as Map<String, dynamic>;
    expect(discountPayload['p_booking_id'], 'booking-b');
    expect(discountPayload['p_discount_amount'], 25);
    expect(discountPayload['p_discount_percentage'], 0);
    expect(
      discountPayload['p_discount_reason'],
      'Manager-approved compensation',
    );

    final paymentPayload =
        jsonDecode(requests[1].body) as Map<String, dynamic>;
    expect(paymentPayload['p_booking_id'], 'booking-b');
    expect(paymentPayload['p_payment_method'], 'cash');

    await client.dispose();
  });
}
