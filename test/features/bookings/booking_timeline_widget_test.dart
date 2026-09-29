import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_timeline_widget.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('BookingTimelineWidget renders lifecycle for active booking', (tester) async {
    final booking = Booking(
      id: 'test-booking-1',
      userId: 'user-1',
      loungeId: 'lounge-1',
      roomId: 'room-1',
      date: DateTime(2026, 10, 1),
      startTime: '14:00',
      endTime: '16:00',
      totalPrice: 200,
      status: BookingStatus.inProgress,
      checkedInAt: DateTime(2026, 10, 1, 14, 5),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        BookingTimelineWidget(booking: booking),
      ),
    );

    expect(find.byType(BookingTimelineWidget), findsOneWidget);
    expect(find.byIcon(Icons.timeline_rounded), findsOneWidget);
  });

  testWidgets('BookingTimelineWidget renders cancelled step for cancelled booking', (tester) async {
    final booking = Booking(
      id: 'test-booking-2',
      userId: 'user-2',
      loungeId: 'lounge-1',
      roomId: 'room-1',
      date: DateTime(2026, 10, 1),
      startTime: '14:00',
      endTime: '16:00',
      totalPrice: 200,
      status: BookingStatus.cancelled,
      cancelledAt: DateTime(2026, 10, 1, 13, 30),
      cancellationReason: 'Customer requested',
    );

    await tester.pumpWidget(
      buildTestableWidget(
        BookingTimelineWidget(booking: booking),
      ),
    );

    expect(find.byType(BookingTimelineWidget), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
  });
}
