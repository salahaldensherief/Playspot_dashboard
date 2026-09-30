import 'package:equatable/equatable.dart';
import 'booking.dart';

class LiveSessionsOperationsGroups extends Equatable {
  @override
  List<Object?> get props => [needsAttention, openTime, running, upcoming];
  final List<Booking> needsAttention;
  final List<Booking> openTime;
  final List<Booking> running;
  final List<Booking> upcoming;

  const LiveSessionsOperationsGroups({
    required this.needsAttention,
    required this.openTime,
    required this.running,
    required this.upcoming,
  });

  factory LiveSessionsOperationsGroups.fromBookings(
    List<Booking> bookings, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final inProgress = bookings
        .where((booking) => booking.status == BookingStatus.inProgress)
        .toList();
    final needsAttention =
        inProgress.where((booking) => _needsAttention(booking, clock)).toList()
          ..sort(
            (a, b) =>
                _urgencyScore(b, clock).compareTo(_urgencyScore(a, clock)),
          );
    final attentionIds = needsAttention.map((booking) => booking.id).toSet();
    final openTime = inProgress
        .where(
          (booking) =>
              booking.isOpenEnded && !attentionIds.contains(booking.id),
        )
        .toList();
    final running =
        inProgress
            .where(
              (booking) =>
                  !booking.isOpenEnded && !attentionIds.contains(booking.id),
            )
            .toList()
          ..sort(
            (a, b) => a
                .remainingDuration(clock)
                .compareTo(b.remainingDuration(clock)),
          );
    final upcoming =
        bookings
            .where((booking) => booking.status == BookingStatus.upcoming)
            .toList()
          ..sort(
            (a, b) => (a.startDateTime ?? a.date).compareTo(
              b.startDateTime ?? b.date,
            ),
          );

    return LiveSessionsOperationsGroups(
      needsAttention: needsAttention,
      openTime: openTime,
      running: running,
      upcoming: upcoming,
    );
  }

  static bool _needsAttention(Booking booking, DateTime now) {
    if (booking.paymentStatus != PaymentStatus.paid) return true;
    if (booking.isOpenEnded) return false;
    return booking.remainingDuration(now) <= const Duration(minutes: 10);
  }

  static int _urgencyScore(Booking booking, DateTime now) {
    var score = booking.paymentStatus != PaymentStatus.paid ? 1000 : 0;
    final remaining = booking.remainingDuration(now);
    if (remaining.isNegative) {
      score += 500 + remaining.inMinutes.abs();
    } else if (remaining <= const Duration(minutes: 10)) {
      score += 200 - remaining.inMinutes;
    }
    return score;
  }
}
