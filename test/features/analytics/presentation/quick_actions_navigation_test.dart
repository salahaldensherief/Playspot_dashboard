import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/quick_actions.dart';
import '../../../support/local_translations_loader.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets('super-admin add lounge reaches the wired provisioning route', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: QuickActionsCard(isSuperAdmin: true)),
        ),
        GoRoute(
          path: RouterKeys.superAdminLounges,
          builder: (_, _) => const Scaffold(body: Text('Provisioning route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        path: 'assets/translations',
        assetLoader: const LocalTranslationsLoader(),
        saveLocale: false,
        child: ScreenUtilInit(
          designSize: const Size(1440, 900),
          builder: (context, _) => MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Lounge'));
    await tester.pumpAndSettle();
    expect(find.text('Provisioning route'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
