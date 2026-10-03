import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_space_type.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/widgets/room_space_type_selector.dart';
import '../../support/local_translations_loader.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final language in ['ar', 'en']) {
    testWidgets('catalog selector $language displays names and retains UUIDs', (
      tester,
    ) async {
      const firstId = '00000000-0000-0000-0000-000000000123';
      const secondId = '00000000-0000-0000-0000-000000000456';
      String? selected;
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(language),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const LocalTranslationsLoader(),
          child: ScreenUtilInit(
            designSize: const Size(1440, 900),
            builder: (context, child) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                body: RoomSpaceTypeSelector(
                  types: const [
                    RoomSpaceType(
                      id: firstId,
                      name: 'open_area',
                      label: 'Open',
                    ),
                    RoomSpaceType(
                      id: secondId,
                      name: 'private',
                      label: 'Private',
                    ),
                  ],
                  selectedId: firstId,
                  onChanged: (value) => selected = value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.initialValue, firstId);
      expect(
        find.text(language == 'ar' ? 'منطقة مفتوحة' : 'Open Area'),
        findsWidgets,
      );
      expect(find.text(firstId), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      final label = language == 'ar' ? 'غرفة قياسية' : 'Standard Room';
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(selected, secondId);
      expect(tester.takeException(), isNull);
    });
  }
}
