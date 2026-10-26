import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source_impl.dart';

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

  test('lost deposit ACK retries with the same operation ID', () async {
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
            'movement_id': 'verified-movement',
            'collected_minor': 2000,
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
    final source = BookingRemoteDataSourceImpl(client);
    Future<void> verify() => source.verifyManualDeposit(
      bookingId: 'booking-a',
      shiftId: 'shift-a',
      evidenceReference: ' BANK-123 ',
      fundsHolder: 'lounge',
    );
    await expectLater(verify(), throwsA(anything));
    await verify();
    final first = jsonDecode(requests[0].body) as Map<String, dynamic>;
    final retry = jsonDecode(requests[1].body) as Map<String, dynamic>;
    expect(
      requests[0].url.path,
      '/rest/v1/rpc/verify_booking_deposit_transfer',
    );
    expect(first['p_evidence_reference'], 'BANK-123');
    expect(first['p_funds_holder'], 'lounge');
    expect(retry['p_operation_id'], first['p_operation_id']);
  });

  test('unmatched deposit receipt cannot report success', () async {
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'booking_id': 'another-booking',
            'movement_id': 'movement',
            'collected_minor': 2000,
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );
    addTearDown(client.dispose);
    await _login(client);
    final source = BookingRemoteDataSourceImpl(client);
    await expectLater(
      source.verifyManualDeposit(
        bookingId: 'booking-a',
        shiftId: 'shift-a',
        evidenceReference: 'BANK-123',
        fundsHolder: 'platform',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
