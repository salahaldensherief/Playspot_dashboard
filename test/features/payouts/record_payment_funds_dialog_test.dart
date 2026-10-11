import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/payouts/domain/entities/payment_funds_review.dart';
import 'package:play_spot_dashboard/features/payouts/domain/repositories/payout_repository.dart';
import 'package:play_spot_dashboard/features/payouts/presentation/widgets/record_payment_funds_dialog.dart';

void main() {
  testWidgets(
    'recipient is never preselected and missing evidence cannot submit on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      sl.registerSingleton<PayoutRepository>(_UnusedRepository());
      addTearDown(() => sl.unregister<PayoutRepository>());
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, child) => MaterialApp(
            home: Scaffold(
              body: RecordPaymentFundsDialog(
                payment: PaymentFundsReview(
                  id: 'payment',
                  loungeId: 'lounge',
                  bookingId: 'booking',
                  paymentMethod: 'instapay',
                  amount: 100,
                  paidAt: DateTime.utc(2026, 10, 12),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final dropdown = tester
          .widget<DropdownButtonFormField<PaymentFundsHolder>>(
            find.byType(DropdownButtonFormField<PaymentFundsHolder>),
          );
      expect(dropdown.initialValue, isNull);
      await tester.tap(find.text('save_changes'));
      await tester.pumpAndSettle();

      expect(find.text('select_funds_holder'), findsOneWidget);
      expect(find.text('funds_evidence_required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _UnusedRepository extends Fake implements PayoutRepository {}
