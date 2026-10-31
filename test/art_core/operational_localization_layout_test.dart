import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/pricing/presentation/widgets/pricing_weekly_preview_bar.dart';
import 'package:play_spot_dashboard/features/system/presentation/widgets/maintenance_overlay.dart';
import '../support/local_translations_loader.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> mount(
    WidgetTester tester,
    String language,
    double width,
    Widget child,
  ) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        startLocale: Locale(language),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const LocalTranslationsLoader(),
        child: ScreenUtilInit(
          designSize: const Size(1440, 900),
          builder: (context, _) => MaterialApp(
            theme: ThemeData(fontFamily: 'Tajawal'),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1000),
                  textScaler: const TextScaler.linear(1.6),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  for (final language in ['ar', 'en']) {
    for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('pricing days and legends $language $width large text', (
        tester,
      ) async {
        await mount(
          tester,
          language,
          width,
          const PricingWeeklyPreviewBar(
            selectedDays: [1, 5],
            startTime: '18:00',
            endTime: '23:00',
            ruleType: 'peak',
          ),
        );
        expect(find.text(language == 'ar' ? 'إث' : 'Mon'), findsOneWidget);
        expect(find.text(language == 'ar' ? 'ذروة' : 'Peak'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
      testWidgets('maintenance uses server message in $language at $width', (
        tester,
      ) async {
        await mount(
          tester,
          language,
          width,
          const MaintenanceOverlayWidget(
            messageAr: 'رسالة الصيانة العربية',
            messageEn: 'English maintenance message',
          ),
        );
        expect(
          find.text(
            language == 'ar'
                ? 'رسالة الصيانة العربية'
                : 'English maintenance message',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            language == 'ar'
                ? 'English maintenance message'
                : 'رسالة الصيانة العربية',
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
