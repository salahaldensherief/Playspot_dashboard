import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/edit_lounge_dialog.dart';
import '../../support/local_translations_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final language in ['ar', 'en']) {
    testWidgets(
      'contact edit preserves separate payment destination $language',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Lounge? saved;
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            startLocale: Locale(language),
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: const LocalTranslationsLoader(),
            child: Builder(
              builder: (context) => ScreenUtilInit(
                designSize: const Size(1024, 1200),
                builder: (context, child) => MaterialApp(
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: Scaffold(
                    body: EditLoungeDialog(
                      lounge: const Lounge(
                        id: 'fixture',
                        name: 'Venue',
                        imageUrl: '',
                        opensAt: '10:00',
                        closesAt: '23:00',
                        city: 'Cairo',
                        contactPhone: '01012345678',
                        vodafoneCashNumber: '01987654321',
                      ),
                      onSave: (value) async {
                        saved = value;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final contact = find.byWidgetPredicate(
          (widget) =>
              widget is AppTextField && widget.label == AppStrings.contactPhone,
        );
        expect(contact, findsOneWidget);
        final input = find.descendant(
          of: contact,
          matching: find.byType(TextFormField),
        );
        await tester.ensureVisible(input);
        await tester.enterText(input, '01234567890');
        await tester.tap(find.text(AppStrings.saveChanges));
        await tester.pumpAndSettle();
        expect(saved?.contactPhone, '01234567890');
        expect(saved?.vodafoneCashNumber, '01987654321');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
