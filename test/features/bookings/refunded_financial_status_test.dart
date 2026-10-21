import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_details_financial_summary.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_financials_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_financials_discount_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/local_translations_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final refundedBooking = Booking(
    id: 'refunded',
    userId: 'customer',
    loungeId: 'branch',
    roomId: 'room',
    date: DateTime(2030, 1, 10),
    startTime: '14:00',
    endTime: '15:00',
    status: BookingStatus.cancelled,
    paymentStatus: PaymentStatus.refunded,
    paymentMethod: 'cash',
    totalPrice: 100,
  );

  Future<void> mount(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        startLocale: const Locale('en'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const LocalTranslationsLoader(),
        child: Builder(
          builder: (context) => ScreenUtilInit(
            designSize: const Size(1920, 1080),
            builder: (_, _) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(body: SingleChildScrollView(child: child)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('refunded booking details do not say unpaid', (tester) async {
    await mount(
      tester,
      BookingDetailsFinancialSummary(booking: refundedBooking),
    );

    expect(find.text('REFUNDED'), findsOneWidget);
    expect(find.text('Unpaid'), findsNothing);
  });

  testWidgets('refunded booking financials cannot offer a new discount', (
    tester,
  ) async {
    final discount = TextEditingController();
    final reason = TextEditingController();
    addTearDown(discount.dispose);
    addTearDown(reason.dispose);
    await mount(
      tester,
      BookingFinancialsCard(
        booking: refundedBooking,
        discountController: discount,
        reasonController: reason,
      ),
    );

    expect(find.text('REFUNDED'), findsOneWidget);
    expect(find.byType(BookingFinancialsDiscountInput), findsNothing);
  });
}
