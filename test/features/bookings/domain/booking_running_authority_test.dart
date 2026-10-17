import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';

void main() {
  final due = Booking(
    id: 'due',
    userId: 'customer',
    loungeId: 'lounge',
    roomId: 'room',
    date: DateTime(2030, 1, 10),
    startTime: '14:00',
    endTime: '15:00',
    durationMinutes: 60,
    totalPrice: 100,
    paymentMethod: 'cash',
    status: BookingStatus.upcoming,
  );
  final now = DateTime(2030, 1, 10, 14, 30);
  test('the clock cannot start a booking or occupy a room', () {
    for (final status in BookingStatus.values) {
      expect(
        due.copyWith(status: status).isBookingActive(now),
        status == BookingStatus.inProgress,
        reason: status.name,
      );
    }
  });
  test(
    'a running session stays visible after its scheduled end until closed',
    () {
      expect(
        due
            .copyWith(status: BookingStatus.inProgress)
            .isBookingActive(DateTime(2030, 1, 11)),
        isTrue,
      );
    },
  );
  test('pending requests cannot leak into the active booking list', () {
    final state = BookingState(
      bookings: [
        due.copyWith(
          date: DateTime.now(),
          startTime: '00:00',
          durationMinutes: 1440,
          status: BookingStatus.pending,
        ),
        due.copyWith(id: 'running', status: BookingStatus.inProgress),
      ],
    );
    expect(state.activeBookings.map((b) => b.id), ['running']);
  });
}
