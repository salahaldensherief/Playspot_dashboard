import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/layouts/top_bar/top_bar_user_profile.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_state.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/lounges_data_table.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/lounges_header.dart';
import '../../support/local_translations_loader.dart';

class _Lounges extends Mock implements LoungeCubit {}

class _Login extends Mock implements LoginCubit {}

Widget _app(double width, double scale, Locale locale, LoungeCubit cubit) {
  final login = _Login();
  when(() => login.state).thenReturn(
    const LoginState(
      user: UserEntity(
        id: 'operator',
        email: 'operator@example.invalid',
        name: 'Operator',
        role: UserRole.superAdmin,
      ),
    ),
  );
  when(() => login.stream).thenAnswer((_) => const Stream.empty());
  final designSize = width < 600
      ? const Size(390, 844)
      : width < 1024
      ? const Size(768, 1024)
      : const Size(1440, 1024);
  return EasyLocalization(
    supportedLocales: const [Locale('ar'), Locale('en')],
    startLocale: locale,
    saveLocale: false,
    path: 'assets/translations',
    assetLoader: const LocalTranslationsLoader(),
    child: Builder(
      builder: (context) => ScreenUtilInit(
        designSize: designSize,
        minTextAdapt: true,
        builder: (context, child) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Tajawal'),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: BlocProvider<LoungeCubit>.value(
            value: cubit,
            child: BlocProvider<LoginCubit>.value(
              value: login,
              child: const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TopBarUserProfile(),
                      LoungesHeader(),
                      SizedBox(height: 20),
                      LoungesDataTable(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

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

  _Lounges fixture() {
    final cubit = _Lounges();
    when(() => cubit.state).thenReturn(
      const LoungeState(
        status: LoungeStatus.success,
        lounges: [
          Lounge(
            id: 'venue',
            name: 'الصالة التجريبية',
            imageUrl: '',
            opensAt: '09:00',
            closesAt: '03:00',
            availableRooms: 7,
            ownerName: 'مدير الصالة',
            status: 'pending',
            isActive: false,
          ),
        ],
      ),
    );
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    return cubit;
  }

  for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 1.6]) {
      for (final language in ['ar', 'en']) {
        testWidgets('management $language width $width scale $scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            _app(width, scale, Locale(language), fixture()),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final action = find.text(
            language == 'ar'
                ? 'إنشاء صالة ومالك جديد'
                : 'Create Lounge & Owner',
          );
          expect(action, findsOneWidget);
          final rect = tester.getRect(action);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
          expect(
            find.textContaining(
              language == 'ar' ? 'السعر حسب الغرفة' : 'Priced per room',
            ),
            findsOneWidget,
          );
          expect(
            Directionality.of(tester.element(find.byType(LoungesHeader))),
            language == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          );
        });
      }
    }
  }

  testWidgets('locale switch updates header and table without Cubit emission', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(1024, 1, const Locale('en'), fixture()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Priced per room'), findsOneWidget);
    expect(find.text('Super Admin'), findsOneWidget);
    await tester
        .element(find.byType(LoungesHeader))
        .setLocale(const Locale('ar'));
    await tester.pumpAndSettle();
    expect(find.text('Create Lounge & Owner'), findsNothing);
    expect(find.text('إنشاء صالة ومالك جديد'), findsOneWidget);
    expect(find.textContaining('Priced per room'), findsNothing);
    expect(find.textContaining('السعر حسب الغرفة'), findsOneWidget);
    expect(find.text('Super Admin'), findsNothing);
    expect(find.text('مدير النظام'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
