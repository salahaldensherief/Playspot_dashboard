import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card_actions.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/cashier_session_tile.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/start_session_button.dart';

void main() {
  final sample = Booking(
    id: 'b',
    userId: 'u',
    loungeId: 'l',
    roomId: 'r',
    date: DateTime(2026),
    startTime: '10:00',
    endTime: '11:00',
    status: BookingStatus.upcoming,
    totalPrice: 100,
    paymentMethod: 'cash',
  );
  test(
    'start eligibility never treats unknown methods or refunds as collected',
    () {
      expect(sample.canStartSession, isTrue);
      expect(
        sample.copyWith(paymentMethod: 'unknown').canStartSession,
        isFalse,
      );
      expect(
        sample.copyWith(paymentMethod: 'manual_transfer').canStartSession,
        isFalse,
      );
      expect(
        sample.copyWith(paymentStatus: PaymentStatus.refunded).canStartSession,
        isFalse,
      );
      expect(
        sample
            .copyWith(
              paymentStatus: PaymentStatus.paid,
              paymentMethod: 'manual_transfer',
            )
            .canStartSession,
        isTrue,
      );
      expect(
        sample.copyWith(status: BookingStatus.cancelled).canStartSession,
        isFalse,
      );
      expect(
        sample.copyWith(status: BookingStatus.inProgress).canStartSession,
        isFalse,
      );
      expect(
        sample
            .copyWith(isOpenTime: true, paymentMethod: 'manual_transfer')
            .canStartSession,
        isTrue,
      );
    },
  );
  for (final surface in ['card', 'cashier tile']) {
    for (final method in ['cash', 'manual_transfer']) {
      testWidgets('$surface unpaid $method start visibility', (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final booking = Booking(
          id: 'booking',
          userId: 'customer',
          loungeId: 'lounge',
          roomId: 'room',
          date: DateTime(2026, 1, 1),
          startTime: '10:00',
          endTime: '11:00',
          status: BookingStatus.upcoming,
          paymentMethod: method,
          paymentStatus: PaymentStatus.unpaid,
          totalPrice: 100,
        );
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(1920, 1080),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: surface == 'card'
                    ? BookingCardActions(
                        booking: booking,
                        isPaid: false,
                        isPending: false,
                        isCanStartSession: true,
                        onOpenDetails: () {},
                      )
                    : CashierSessionTile(
                        booking: booking,
                        selected: false,
                        onSelect: () {},
                      ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.byType(StartSessionButton),
          method == 'cash' ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
