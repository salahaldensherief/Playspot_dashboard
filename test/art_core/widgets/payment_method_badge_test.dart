import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/widgets/payment_method_badge.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('PaymentMethodBadge renders cash icon and text', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const PaymentMethodBadge(isCash: true),
      ),
    );

    expect(find.byType(PaymentMethodBadge), findsOneWidget);
    expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
  });

  testWidgets('PaymentMethodBadge renders wallet icon and text', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PaymentMethodBadge.fromBookingPaymentMethod('manual_transfer'),
      ),
    );

    expect(find.byType(PaymentMethodBadge), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
  });

  testWidgets('PaymentMethodBadge renders instapay icon', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PaymentMethodBadge.fromBookingPaymentMethod('instapay'),
      ),
    );

    expect(find.byType(PaymentMethodBadge), findsOneWidget);
    expect(find.byIcon(Icons.send_to_mobile_rounded), findsOneWidget);
  });
}
