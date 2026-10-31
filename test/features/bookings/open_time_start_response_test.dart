import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const roomId = '00000000-0000-0000-0000-000000000002';
  const bookingId = '00000000-0000-0000-0000-000000000003';
  late SupabaseClient client;
  late Object? responseBody;

  setUp(() {
    responseBody = {
      'success': true,
      'room_id': roomId,
      'booking_id': bookingId,
      'status': 'in_progress',
      'is_open_time': true,
      'started_at': '2026-10-24T12:00:00Z',
    };
    client = SupabaseClient(
      'https://start-fixture.invalid',
      'public-fixture-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        expect(request.url.path, endsWith('/rpc/start_open_time_session'));
        expect(jsonDecode(request.body)['p_room_id'], roomId);
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

  test('accepts confirmed start for the requested room', () async {
    final result = await BookingRemoteDataSourceImpl(
      client,
    ).startOpenTimeSession(roomId: roomId);
    expect(result['booking_id'], bookingId);
  });

  for (final invalid in <Object?>[
    {'success': true},
    {
      'success': false,
      'room_id': roomId,
      'booking_id': bookingId,
      'status': 'in_progress',
      'is_open_time': true,
      'started_at': '2026-10-24T12:00:00Z',
    },
    {
      'success': true,
      'room_id': 'another-room',
      'booking_id': bookingId,
      'status': 'in_progress',
      'is_open_time': true,
      'started_at': '2026-10-24T12:00:00Z',
    },
    {
      'success': true,
      'room_id': roomId,
      'booking_id': bookingId,
      'status': 'completed',
      'is_open_time': true,
      'started_at': '2026-10-24T12:00:00Z',
    },
    {
      'success': true,
      'room_id': roomId,
      'booking_id': bookingId,
      'status': 'in_progress',
      'is_open_time': true,
      'started_at': 'invalid',
    },
    [],
  ]) {
    test('rejects unconfirmed start response $invalid', () async {
      responseBody = invalid;
      await expectLater(
        BookingRemoteDataSourceImpl(
          client,
        ).startOpenTimeSession(roomId: roomId),
        throwsFormatException,
      );
    });
  }
}
