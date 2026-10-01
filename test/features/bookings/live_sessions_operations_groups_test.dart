import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/live_sessions_operations_board.dart';

void main() {
  final now = DateTime(2026, 9, 29, 18);

  Booking booking({
    required String id,
    required BookingStatus status,
    PaymentStatus paymentStatus = PaymentStatus.paid,
    int durationMinutes = 60,
    String startTime = '18:00',
  }) {
    return Booking(
      id: id,
      userId: 'user-$id',
      loungeId: 'lounge-a',
      roomId: 'room-$id',
      roomName: 'Room $id',
      date: DateTime(2026, 9, 29),
      startTime: startTime,
      endTime: '19:00',
      durationMinutes: durationMinutes,
      status: status,
      paymentStatus: paymentStatus,
      totalPrice: 100,
    );
  }

  test('groups sessions by operational priority without duplicates', () {
    final groups = LiveSessionsOperationsGroups.fromBookings([
      booking(
        id: 'unpaid',
        status: BookingStatus.inProgress,
        paymentStatus: PaymentStatus.unpaid,
      ),
      booking(
        id: 'ending',
        status: BookingStatus.inProgress,
        startTime: '17:05',
      ),
      booking(id: 'open', status: BookingStatus.inProgress, durationMinutes: 0),
      booking(
        id: 'running',
        status: BookingStatus.inProgress,
        startTime: '18:00',
      ),
      booking(
        id: 'upcoming',
        status: BookingStatus.upcoming,
        startTime: '20:00',
      ),
    ], now: now);

    expect(groups.needsAttention.map((item) => item.id), ['unpaid', 'ending']);
    expect(groups.openTime.single.id, 'open');
    expect(groups.running.single.id, 'running');
    expect(groups.upcoming.single.id, 'upcoming');

    final allIds = [
      ...groups.needsAttention,
      ...groups.openTime,
      ...groups.running,
      ...groups.upcoming,
    ].map((item) => item.id);
    expect(allIds.toSet(), hasLength(allIds.length));
  });
  test('elapsed open time cannot outrank an unpaid session ending soon', () {
    final ending = booking(
      id: 'ending',
      status: BookingStatus.inProgress,
      paymentStatus: PaymentStatus.unpaid,
      startTime: '17:05',
    );
    final open = booking(
      id: 'open',
      status: BookingStatus.inProgress,
      paymentStatus: PaymentStatus.unpaid,
      startTime: '17:58',
      durationMinutes: 0,
    );
    final groups = LiveSessionsOperationsGroups.fromBookings([
      open,
      ending,
    ], now: now);
    expect(groups.needsAttention.map((item) => item.id), ['ending', 'open']);
  });
  test(
    'equal priorities retain a deterministic order across input reorder',
    () {
      final first = booking(
        id: 'first',
        status: BookingStatus.inProgress,
        paymentStatus: PaymentStatus.unpaid,
      );
      final second = booking(
        id: 'second',
        status: BookingStatus.inProgress,
        paymentStatus: PaymentStatus.unpaid,
      );
      final a = LiveSessionsOperationsGroups.fromBookings([
        first,
        second,
      ], now: now);
      final b = LiveSessionsOperationsGroups.fromBookings([
        second,
        first,
      ], now: now);
      expect(a.needsAttention.map((item) => item.id), ['first', 'second']);
      expect(a.needsAttention, b.needsAttention);
    },
  );
}
