import 'package:equatable/equatable.dart';
import '../../domain/entities/booking.dart';

class SessionOperationsSummary extends Equatable {
  final Booking booking;
  final Booking? nextBooking;
  const SessionOperationsSummary(this.booking, this.nextBooking);

  factory SessionOperationsSummary.fromBookings(
    Booking booking,
    List<Booking> all,
  ) {
    final next =
        all
            .where(
              (item) =>
                  item.id != booking.id &&
                  item.roomId == booking.roomId &&
                  item.status == BookingStatus.upcoming &&
                  item.startDateTime != null,
            )
            .toList()
          ..sort(
            (a, b) => (a.startDateTime ?? a.date).compareTo(
              b.startDateTime ?? b.date,
            ),
          );
    return SessionOperationsSummary(booking, next.isEmpty ? null : next.first);
  }
  bool get hasConflict {
    final next = nextBooking?.startDateTime;
    final end = booking.endDateTime;
    return next != null &&
        (booking.isOpenEnded || (end != null && next.isBefore(end)));
  }

  @override
  List<Object?> get props => [booking, nextBooking];
}
