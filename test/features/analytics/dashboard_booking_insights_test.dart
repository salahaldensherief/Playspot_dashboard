import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/analytics/domain/entities/dashboard_booking_insights.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

void main() {
  final day = DateTime(2026, 10, 2);
  Booking invoice(
    String id, {
    double price = 200,
    BookingStatus status = BookingStatus.completed,
    PaymentStatus paid = PaymentStatus.paid,
    DateTime? date,
    int? visit,
    double? addons,
    int minutes = 60,
  }) => Booking(
    id: id,
    userId: 'u',
    loungeId: 'l',
    roomId: 'r',
    date: date ?? day,
    startTime: '10:00',
    endTime: '11:00',
    status: status,
    paymentStatus: paid,
    totalPrice: price,
    visitNumber: visit,
    addonsPrice: addons,
    durationMinutes: minutes,
  );

  test('empty data has no sample percentages, spend or duration', () {
    final insights = DashboardBookingInsights([], day: day);
    expect(insights.count, 0);
    expect(insights.averageSpend, isNull);
    expect(insights.averageHours, isNull);
    expect(insights.repeatPercent, isNull);
    expect(insights.canteenAttachPercent, isNull);
  });

  test('only completed paid invoices for this day contribute', () {
    final insights = DashboardBookingInsights([
      invoice('a', price: 100, visit: 1),
      invoice('b', price: 300, visit: 2, addons: 50, minutes: 120),
      invoice('pending', status: BookingStatus.pending),
      invoice('cancelled', status: BookingStatus.cancelled),
      invoice('unpaid', paid: PaymentStatus.unpaid),
      invoice('other-day', date: day.subtract(const Duration(days: 1))),
      invoice('invalid', price: double.nan),
      invoice('negative', price: -1),
    ], day: day);
    expect(insights.count, 2);
    expect(insights.averageSpend, 200);
    expect(insights.averageHours, 1.5);
    expect(insights.canteenAttachPercent, 50);
    expect(insights.repeatPercent, 50);
  });

  test(
    'unknown visits and open-ended duration are not invented from defaults',
    () {
      final insights = DashboardBookingInsights([
        invoice('a', price: 0, minutes: 0),
      ], day: day);
      expect(insights.count, 1);
      expect(insights.averageSpend, 0);
      expect(insights.canteenAttachPercent, 0);
      expect(insights.repeatPercent, isNull);
      expect(insights.averageHours, isNull);
    },
  );
}
