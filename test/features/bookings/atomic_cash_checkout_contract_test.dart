import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source_impl.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/cash_checkout_operation_store.dart';

Future<void> _login(SupabaseClient client) => client.auth.recoverSession(
  jsonEncode({
    'access_token': 'synthetic-token',
    'refresh_token': 'synthetic-refresh',
    'token_type': 'bearer',
    'user': {
      'id': 'cashier-a',
      'aud': 'authenticated',
      'app_metadata': {},
      'user_metadata': {},
      'created_at': '2026-01-01T00:00:00Z',
    },
  }),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('simultaneous retries reserve one durable operation ID', () async {
    const store = CashCheckoutOperationStore();
    final ids = await Future.wait([
      store.getOrCreate('cashier|booking|shift|remaining'),
      store.getOrCreate('cashier|booking|shift|remaining'),
    ]);
    expect(ids[0], ids[1]);
    expect(await store.getOrCreate('cashier|booking|shift|remaining'), ids[0]);
  });

  test('one atomic RPC confirms the matching canonical receipt', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'booking_id': payload['p_booking_id'],
            'shift_id': payload['p_shift_id'],
            'operation_id': payload['p_operation_id'],
            'shift_payment_id': 'ledger-row',
            'collected_minor': 5000,
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    await _login(client);
    await BookingRemoteDataSourceImpl(client).confirmCashPayment(
      'booking-a',
      shiftId: 'shift-a',
      discountAmount: 25,
      discountReason: 'Approved compensation',
    );
    expect(requests, hasLength(1));
    expect(
      requests.single.url.path,
      '/rest/v1/rpc/checkout_booking_cash_atomic',
    );
    final payload = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(payload['p_shift_id'], 'shift-a');
    expect(payload['p_amount_minor'], isNull);
    expect(payload['p_discount_amount'], 25);
    expect(payload['p_discount_percentage'], 0);
    expect(payload['p_operation_id'], isNotNull);
  });

  test('lost response retries with the persisted operation ID', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (requests.length == 1) {
          return http.Response('unavailable', 503, request: request);
        }
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'booking_id': payload['p_booking_id'],
            'shift_id': payload['p_shift_id'],
            'operation_id': payload['p_operation_id'],
            'shift_payment_id': 'same-ledger-row',
            'collected_minor': 9000,
            'replayed': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    await _login(client);
    await expectLater(
      BookingRemoteDataSourceImpl(
        client,
      ).confirmCashPayment('booking-b', shiftId: 'shift-a'),
      throwsA(anything),
    );
    await BookingRemoteDataSourceImpl(
      client,
    ).confirmCashPayment('booking-b', shiftId: 'shift-a');
    final first = jsonDecode(requests[0].body) as Map<String, dynamic>;
    final retry = jsonDecode(requests[1].body) as Map<String, dynamic>;
    expect(retry['p_operation_id'], first['p_operation_id']);
  });

  test(
    'mismatched receipt and conflicting discount cannot report success',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({'booking_id': 'another', 'shift_payment_id': 'row'}),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      await _login(client);
      final source = BookingRemoteDataSourceImpl(client);
      await expectLater(
        source.confirmCashPayment('booking-c', shiftId: 'shift-a'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        source.confirmCashPayment(
          'booking-c',
          shiftId: 'shift-a',
          discountAmount: 10,
          discountPercentage: 10,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(requests, hasLength(1));
    },
  );
}
