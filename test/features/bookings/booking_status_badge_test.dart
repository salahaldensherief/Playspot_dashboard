import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_status_badge.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('BookingStatusBadge renders for inProgress status', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const BookingStatusBadge(status: BookingStatus.inProgress),
      ),
    );

    expect(find.byType(BookingStatusBadge), findsOneWidget);
  });

  testWidgets('BookingStatusBadge handles client cancelled badge', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const BookingStatusBadge(
          status: BookingStatus.cancelled,
          isCancelledByClient: true,
        ),
      ),
    );

    expect(find.byType(BookingStatusBadge), findsOneWidget);
  });
}
