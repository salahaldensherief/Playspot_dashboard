import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/core/router/access_loading_page.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_state.dart';
import '../../support/local_translations_loader.dart';

class _Auth extends Mock implements LoginCubit {}

class _Permissions extends Mock implements PermissionsCubit {}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final language in ['ar', 'en']) {
    testWidgets(
      'profile failure offers retry and explicit logout in $language',
      (tester) async {
        tester.view.physicalSize = const Size(360, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = _Auth();
        final permissions = _Permissions();
        when(
          () => auth.state,
        ).thenReturn(const LoginState(status: LoginStatus.profileFailure));
        when(() => auth.stream).thenAnswer((_) => const Stream.empty());
        when(() => auth.checkInitialAuth()).thenAnswer((_) async {});
        when(() => auth.logout()).thenAnswer((_) async {});
        when(() => permissions.state).thenReturn(PermissionsState.initial());
        when(() => permissions.stream).thenAnswer((_) => const Stream.empty());
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            path: 'assets/translations',
            assetLoader: const LocalTranslationsLoader(),
            startLocale: Locale(language),
            saveLocale: false,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.6),
                  ),
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider<LoginCubit>.value(value: auth),
                      BlocProvider<PermissionsCubit>.value(value: permissions),
                    ],
                    child: const AccessLoadingPage(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('profile_access_load_failed'.tr()), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.tap(find.text('retry'.tr()));
        verify(() => auth.checkInitialAuth()).called(1);
        await tester.tap(find.text('logout'.tr()));
        verify(() => auth.logout()).called(1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
