import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/manual_payment_verification_dialog.dart';

void main() {
  testWidgets('payment verification dialog fits a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final booking = Booking(
      id: 'booking-1',
      userId: 'user-1',
      userName: 'Test Customer',
      userPhone: '01000000000',
      loungeId: 'lounge-1',
      roomId: 'room-1',
      roomName: 'Room A',
      date: DateTime(2026, 9, 29),
      startTime: '18:00',
      endTime: '19:00',
      status: BookingStatus.pendingVerification,
      totalPrice: 150,
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: ManualPaymentVerificationDialog(
              booking: booking,
              receiptUrlResolver: (_) async => null,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Test Customer'), findsOneWidget);
    expect(find.text('Room A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
