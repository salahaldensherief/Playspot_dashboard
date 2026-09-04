import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

void main() {
  group('BookingStatus Extensions & Parsing Tests', () {
    test('BookingStatusX.fromString parses all database variants correctly', () {
      expect(BookingStatusX.fromString('in_progress'), BookingStatus.inProgress);
      expect(BookingStatusX.fromString('inprogress'), BookingStatus.inProgress);
      expect(BookingStatusX.fromString('active'), BookingStatus.inProgress);

      expect(BookingStatusX.fromString('upcoming'), BookingStatus.upcoming);
      expect(BookingStatusX.fromString('completed'), BookingStatus.completed);

      expect(BookingStatusX.fromString('cancelled'), BookingStatus.cancelled);
      expect(BookingStatusX.fromString('canceled'), BookingStatus.cancelled);
      expect(BookingStatusX.fromString('no_show'), BookingStatus.cancelled);
      expect(BookingStatusX.fromString('rejected'), BookingStatus.cancelled);

      expect(BookingStatusX.fromString('pending'), BookingStatus.pending);
      expect(BookingStatusX.fromString(null), BookingStatus.pending);
    });

    test('BookingStatusX.toDbString serializes correctly', () {
      expect(BookingStatus.inProgress.toDbString(), 'in_progress');
      expect(BookingStatus.upcoming.toDbString(), 'upcoming');
      expect(BookingStatus.completed.toDbString(), 'completed');
      expect(BookingStatus.cancelled.toDbString(), 'cancelled');
      expect(BookingStatus.pending.toDbString(), 'pending');
    });

    test('Booking copyWith immutability test', () {
      final now = DateTime.now();
      final booking = Booking(
        id: 'b1',
        userId: 'u1',
        loungeId: 'l1',
        roomId: 'r1',
        date: now,
        startTime: '12:00',
        endTime: '13:00',
        durationMinutes: 60,
        status: BookingStatus.inProgress,
        totalPrice: 100.0,
      );

      final updated = booking.copyWith(status: BookingStatus.completed, totalPrice: 150.0);

      expect(updated.id, 'b1');
      expect(updated.status, BookingStatus.completed);
      expect(updated.totalPrice, 150.0);
      expect(booking.status, BookingStatus.inProgress);
    });
  });
}
