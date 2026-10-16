import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/canteen/domain/entities/canteen_combo_entity.dart';
import 'package:play_spot_dashboard/features/canteen/domain/entities/upsell_rule_entity.dart';
import 'package:play_spot_dashboard/features/canteen/presentation/widgets/combo_card.dart';
import 'package:play_spot_dashboard/features/canteen/presentation/widgets/upsell_rule_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/local_translations_loader.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> mount(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        startLocale: const Locale('en'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const LocalTranslationsLoader(),
        child: ScreenUtilInit(
          designSize: const Size(1440, 900),
          builder: (context, _) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(body: SizedBox(width: 900, child: child)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('combo card is read-only without menu permission', (
    tester,
  ) async {
    await mount(
      tester,
      ComboCard(
        combo: const CanteenComboEntity(
          id: 'combo-1',
          loungeId: 'lounge-1',
          nameAr: 'كومبو',
          price: 80,
        ),
        canManage: false,
        onEdit: () => fail('edit must not be available'),
        onDelete: () => fail('delete must not be available'),
        onToggleActive: (_) => fail('toggle must not be available'),
      ),
    );

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('combo card exposes controls to permitted editor', (
    tester,
  ) async {
    await mount(
      tester,
      ComboCard(
        combo: const CanteenComboEntity(
          id: 'combo-1',
          loungeId: 'lounge-1',
          nameAr: 'كومبو',
          price: 80,
        ),
        canManage: true,
        onEdit: () {},
        onDelete: () {},
        onToggleActive: (_) {},
      ),
    );
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('upsell rule card is read-only without menu permission', (
    tester,
  ) async {
    await mount(
      tester,
      UpsellRuleCard(
        rule: const UpsellRuleEntity(
          id: 'rule-1',
          loungeId: 'lounge-1',
          triggerType: 'session_start',
          suggestedNameAr: 'كومبو',
        ),
        canManage: false,
        onEdit: () => fail('edit must not be available'),
        onDelete: () => fail('delete must not be available'),
        onToggleActive: (_) => fail('toggle must not be available'),
      ),
    );
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(tester.takeException(), isNull);
  });
}
