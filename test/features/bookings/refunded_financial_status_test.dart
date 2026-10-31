import 'package:easy_localization/easy_localization.dart' hide TextDirection;
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

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        startLocale: locale,
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
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: Scaffold(body: SingleChildScrollView(child: child)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.element(find.byType(Scaffold)).setLocale(locale);
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

  testWidgets('financial card fits a narrow cashier viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, BookingFinancialsCard(booking: refundedBooking));
    expect(tester.takeException(), isNull);
    expect(find.text('REFUNDED'), findsOneWidget);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('financial card supports $language at enlarged text size', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        BookingFinancialsCard(booking: refundedBooking),
        locale: Locale(language),
        textScale: 1.6,
      );
      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.byType(BookingFinancialsCard))),
        language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
    });
  }

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
