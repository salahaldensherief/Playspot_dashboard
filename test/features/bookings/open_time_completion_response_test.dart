import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const bookingId = '00000000-0000-0000-0000-000000000001';
  late SupabaseClient client;
  late Object? responseBody;

  setUp(() {
    responseBody = {
      'success': true,
      'booking_id': bookingId,
      'status': 'completed',
      'final_total': 120,
    };
    client = SupabaseClient(
      'https://completion-fixture.invalid',
      'public-fixture-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        expect(request.url.path, endsWith('/rpc/complete_booking_session'));
        expect(jsonDecode(request.body)['p_booking_id'], bookingId);
        return http.Response(
          jsonEncode(responseBody),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
  });

  tearDown(() => client.dispose());

  test('accepts confirmed completion for the requested booking', () async {
    final result = await BookingRemoteDataSourceImpl(
      client,
    ).completeOpenTimeSession(bookingId);
    expect(result['final_total'], 120);
  });

  for (final invalid in <Object?>[
    {'success': false, 'booking_id': bookingId, 'status': 'in_progress'},
    {'success': true, 'booking_id': 'another-booking', 'status': 'completed'},
    {'success': true, 'booking_id': bookingId, 'status': 'in_progress'},
    [],
  ]) {
    test('rejects unconfirmed completion response $invalid', () async {
      responseBody = invalid;
      await expectLater(
        BookingRemoteDataSourceImpl(client).completeOpenTimeSession(bookingId),
        throwsFormatException,
      );
    });
  }
}
