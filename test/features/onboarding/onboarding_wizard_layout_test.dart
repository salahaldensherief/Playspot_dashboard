import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_cubit.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_state.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/entities/lounge_draft_params.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/widgets/lounge_setup_view.dart';
import '../../support/local_translations_loader.dart';

class _Onboarding extends Mock implements OnboardingCubit {}

class _Login extends Mock implements LoginCubit {}

class _Kyc extends Mock implements KycCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await (FontLoader(
          'Tajawal',
        )..addFont(rootBundle.load('assets/fonts/Tajawal/Tajawal-Regular.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 1.6]) {
      for (var step = 0; step < 9; step++) {
        testWidgets('Arabic wizard width $width scale $scale step $step', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final onboarding = _Onboarding();
          final login = _Login();
          final kyc = _Kyc();
          when(
            () => onboarding.state,
          ).thenReturn(OnboardingState(draft: LoungeDraftParams(step: step)));
          when(() => onboarding.stream).thenAnswer((_) => const Stream.empty());
          when(() => login.state).thenReturn(const LoginState());
          when(() => login.stream).thenAnswer((_) => const Stream.empty());
          when(() => kyc.state).thenReturn(const KycState());
          when(() => kyc.stream).thenAnswer((_) => const Stream.empty());
          final captureKey = GlobalKey();
          await tester.pumpWidget(
            EasyLocalization(
              supportedLocales: const [Locale('ar'), Locale('en')],
              startLocale: const Locale('ar'),
              saveLocale: false,
              path: 'assets/translations',
              assetLoader: const LocalTranslationsLoader(),
              child: Builder(
                builder: (context) => ScreenUtilInit(
                  designSize: const Size(1920, 1080),
                  builder: (context, child) => MaterialApp(
                    locale: context.locale,
                    supportedLocales: context.supportedLocales,
                    localizationsDelegates: context.localizationDelegates,
                    theme: ThemeData.dark().copyWith(
                      textTheme: ThemeData.dark().textTheme.apply(
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(scale)),
                      child: child ?? const SizedBox.shrink(),
                    ),
                    home: BlocProvider<LoginCubit>.value(
                      value: login,
                      child: BlocProvider<KycCubit>.value(
                        value: kyc,
                        child: BlocProvider<OnboardingCubit>.value(
                          value: onboarding,
                          child: RepaintBoundary(
                            key: captureKey,
                            child: const LoungeSetupView(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            Directionality.of(tester.element(find.byType(LoungeSetupView))),
            ui.TextDirection.rtl,
          );
          if (scale == 1.6) {
            await tester.runAsync(() async {
              final boundary =
                  captureKey.currentContext?.findRenderObject()
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 1);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              if (bytes != null) {
                final file = File(
                  'C:/Users/salah/Documents/Codex/2026-09-30/playspot-chatgpt-remotes-git-fetch-origin/outputs/onboarding-screenshots/step-$step-ar-${width.toInt()}-$scale.png',
                );
                file.parent.createSync(recursive: true);
                file.writeAsBytesSync(bytes.buffer.asUint8List());
              }
            });
          }
        });
      }
    }
  }
}
