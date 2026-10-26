import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source_impl.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

void main() {
  test('walk-in creation has no client-side session or room fallback', () {
    final source = File(
      'lib/features/bookings/data/datasources/booking_mutation_helper.dart',
    ).readAsStringSync();

    expect(source, contains("'create_manual_booking_admin'"));
    expect(source, isNot(contains("client.rpc('start_booking_session'")));
    expect(source, isNot(contains(".from('rooms')")));
  });

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

  test(
    'approved upcoming booking with unpaid cash status parses as upcoming, not pending',
    () {
      final rawBooking = {
        'id': 'booking-cash-upcoming',
        'user_id': 'user-1',
        'lounge_id': 'lounge-1',
        'room_id': 'room-1',
        'date': '2026-10-11T12:00:00Z',
        'start_time': '14:00',
        'end_time': '15:00',
        'duration_minutes': 60,
        'status': 'upcoming',
        'payment_status': 'unpaid',
        'payment_method': 'cash',
        'total_price': 50.0,
      };

      final model = BookingModel.fromJson(rawBooking);

      expect(model.status, BookingStatus.upcoming);
      expect(model.paymentStatus, PaymentStatus.unpaid);
    },
  );

  test('partially paid extension remains distinguishable from unpaid', () {
    final model = BookingModel.fromJson({
      'id': 'booking-extension',
      'user_id': 'user-1',
      'lounge_id': 'lounge-1',
      'room_id': 'room-1',
      'date': '2026-10-11',
      'start_time': '14:00',
      'end_time': '15:30',
      'status': 'in_progress',
      'payment_status': 'partial',
      'payment_method': 'cash',
      'total_price': 230,
    });
    expect(model.paymentStatus, PaymentStatus.partial);
    expect(model.totalPrice, 230);
  });

  test(
    'cash payment requires an authenticated cashier and active shift',
    () async {
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

      await expectLater(
        source.confirmCashPayment('booking-a'),
        throwsA(isA<StateError>()),
      );
      expect(requests, isEmpty);

      await client.dispose();
    },
  );

  test('invalid simultaneous discount modes never send money', () async {
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

    await expectLater(
      source.confirmCashPayment(
        'booking-b',
        shiftId: 'shift-a',
        discountAmount: 25,
        discountPercentage: 10,
      ),
      throwsA(isA<StateError>()),
    );
    expect(requests, isEmpty);

    await client.dispose();
  });
  test('session start cannot acknowledge another booking as success', () async {
    final client = SupabaseClient(
      'https://example.invalid',
      'fixture',
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode(
            request.url.path.endsWith('/bookings')
                ? {'is_open_time': false}
                : {
                    'success': true,
                    'booking_id': 'other',
                    'status': 'in_progress',
                  },
          ),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    await expectLater(
      BookingRemoteDataSourceImpl(client).startBookingSession('requested'),
      throwsA(isA<FormatException>()),
    );
  });
}
