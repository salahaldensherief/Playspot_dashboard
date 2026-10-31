import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/local_translations_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('field combines required and language validation', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        startLocale: const Locale('en'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const LocalTranslationsLoader(),
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: Form(
                key: formKey,
                child: const AppTextField(
                  label: 'English name',
                  textLanguage: TextFieldLanguage.english,
                  validator: _required,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(formKey.currentState!.validate(), isFalse);
    await tester.enterText(find.byType(TextFormField), 'صالة');
    await tester.pump();
    expect(formKey.currentState!.validate(), isFalse);
    await tester.enterText(find.byType(TextFormField), 'Lounge');
    await tester.pump();
    expect(formKey.currentState!.validate(), isTrue);
  });
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;
