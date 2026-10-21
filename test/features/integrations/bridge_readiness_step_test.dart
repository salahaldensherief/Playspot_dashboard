import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/integrations/presentation/widgets/bridge_readiness_step.dart';
import '../../support/local_translations_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final language in ['ar', 'en']) {
    testWidgets(
      '$language conditional questions, direction and narrow layout',
      (tester) async {
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var answers = <String, dynamic>{
          'system': 'cloud',
          'supportsApi': 'yes',
          'apiReachability': 'localNetwork',
        };
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            startLocale: Locale(language),
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: const LocalTranslationsLoader(),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: StatefulBuilder(
                      builder: (context, setState) => BridgeReadinessStep(
                        answers: answers,
                        onChanged: (value) => setState(() => answers = value),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          Directionality.of(tester.element(find.byType(BridgeReadinessStep))),
          language == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        );
        expect(
          find.byKey(const ValueKey('bridge_cloud_hasWindowsComputer_')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('bridge_cloud_outboundInternetAvailable_')),
          findsNothing,
        );
        final api = find.byKey(const ValueKey('bridge_cloud_supportsApi_yes'));
        await tester.ensureVisible(api);
        await tester.tap(api);
        await tester.pumpAndSettle();
        await tester.tap(find.text('bridge_step.options.no'.tr()).last);
        await tester.pumpAndSettle();
        expect(answers.containsKey('apiReachability'), isFalse);
        expect(
          find.byKey(const ValueKey('bridge_cloud_hasWindowsComputer_')),
          findsNothing,
        );
        final vendor = find.byKey(const ValueKey('bridge_cloud_vendorName'));
        await tester.ensureVisible(vendor);
        await tester.enterText(vendor, 'Old vendor');
        final system = find.byKey(const ValueKey('bridge_cloud_system_cloud'));
        await tester.ensureVisible(system);
        await tester.tap(system);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('bridge_step.options.windowsLocal'.tr()).last,
        );
        await tester.pumpAndSettle();
        expect(answers, {'system': 'windowsLocal'});
        final resetVendor = find.byKey(
          const ValueKey('bridge_windowsLocal_vendorName'),
        );
        expect(tester.widget<TextFormField>(resetVendor).initialValue, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
