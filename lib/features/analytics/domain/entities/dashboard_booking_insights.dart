import '../../../bookings/domain/entities/booking.dart';

/// Describes the loaded, completed and fully paid invoices for one day.
/// This is a sample, not a replacement for server financial aggregates.
class DashboardBookingInsights {
  DashboardBookingInsights(
    Iterable<Booking> bookings, {
    required DateTime day,
  }) {
    final measured = bookings
        .where(
          (booking) =>
              booking.date.year == day.year &&
              booking.date.month == day.month &&
              booking.date.day == day.day &&
              booking.status == BookingStatus.completed &&
              booking.paymentStatus == PaymentStatus.paid &&
              booking.totalPrice.isFinite &&
              booking.totalPrice >= 0,
        )
        .toList();
    count = measured.length;
    if (measured.isEmpty) {
      averageSpend = null;
      averageHours = null;
      canteenAttachPercent = null;
      repeatPercent = null;
      return;
    }
    averageSpend =
        measured.fold<double>(0, (sum, b) => sum + b.totalPrice) / count;
    final durations = measured.where((b) => b.durationMinutes > 0).toList();
    if (durations.isEmpty) {
      averageHours = null;
    } else {
      averageHours =
          durations.fold<double>(0, (sum, b) => sum + b.durationMinutes) /
          durations.length /
          60;
    }
    canteenAttachPercent =
        measured
            .where(
              (b) => (b.addonsPrice ?? 0) > 0 || b.canteenOrders.isNotEmpty,
            )
            .length *
        100 /
        count;
    final knownVisits = measured
        .where((b) => (b.visitNumber ?? 0) > 0)
        .toList();
    if (knownVisits.isEmpty) {
      repeatPercent = null;
    } else {
      repeatPercent =
          knownVisits.where((b) => (b.visitNumber ?? 0) > 1).length *
          100 /
          knownVisits.length;
    }
  }

  late final int count;
  late final double? averageSpend;
  late final double? averageHours;
  late final double? canteenAttachPercent;
  late final double? repeatPercent;
}
