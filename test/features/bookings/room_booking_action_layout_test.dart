import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_available_section.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/shifts/domain/entities/shift_entity.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/shift_header_banner.dart';
import '../../support/local_translations_loader.dart';

class _Login extends Mock implements LoginCubit {}

class _Shift extends Mock implements ShiftCubit {}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final language in ['ar', 'en']) {
    for (final width in [240.0, 300.0, 500.0]) {
      testWidgets(
        'room booking actions remain readable $language $width with large text',
        (tester) async {
          tester.view.physicalSize = const Size(600, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final login = _Login();
          when(() => login.state).thenReturn(const LoginState());
          when(() => login.stream).thenAnswer((_) => const Stream.empty());
          final section = BlocProvider<LoginCubit>.value(
            value: login,
            child: Center(
              child: SizedBox(
                width: width,
                child: const RoomOccupancyAvailableSection(
                  loungeId: 'venue',
                  room: RoomEntity(
                    id: 'room',
                    loungeId: 'venue',
                    nameAr: 'غرفة',
                    nameEn: 'Room',
                    hourlyRateSingle: 50,
                    hourlyRateMulti: 80,
                    isAvailable: true,
                    images: [],
                    featuresAr: [],
                    featuresEn: [],
                  ),
                ),
              ),
            ),
          );
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
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: Scaffold(
                    body: MediaQuery(
                      data: const MediaQueryData(
                        size: Size(600, 1200),
                        textScaler: TextScaler.linear(1.6),
                      ),
                      child: section,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final quick = tester.getRect(
            find.widgetWithText(AppButton, AppStrings.walkInBooking),
          );
          final detailed = tester.getRect(
            find.widgetWithText(AppButton, AppStrings.detailedBooking),
          );
          expect(quick.width, greaterThan(200));
          expect(detailed.top, greaterThanOrEqualTo(quick.bottom));
          expect(find.textContaining('50'), findsOneWidget);
          expect(find.textContaining('80'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
    testWidgets(
      'shift actions stay within viewport at $width with large text',
      (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final login = _Login();
        when(() => login.state).thenReturn(
          const LoginState(
            user: UserEntity(
              id: 'cashier',
              email: 'test@example.test',
              name: 'Cashier',
              role: UserRole.cashier,
              loungeId: 'venue',
            ),
          ),
        );
        when(() => login.stream).thenAnswer((_) => const Stream.empty());
        final shift = _Shift();
        when(() => shift.state).thenReturn(
          ShiftState(
            status: ShiftStatus.active,
            activeShift: ShiftEntity(
              id: 'shift',
              cashierId: 'cashier',
              loungeId: 'venue',
              cashierName: 'Cashier',
              startingCash: 0,
              status: 'open',
              startTime: DateTime.utc(2026, 10, 4, 10),
            ),
          ),
        );
        when(() => shift.stream).thenAnswer((_) => const Stream.empty());
        final banner = MultiBlocProvider(
          providers: [
            BlocProvider<LoginCubit>.value(value: login),
            BlocProvider<ShiftCubit>.value(value: shift),
          ],
          child: const Align(
            alignment: Alignment.topCenter,
            child: ShiftHeaderBanner(),
          ),
        );
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('ar')],
            startLocale: const Locale('ar'),
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: const LocalTranslationsLoader(),
            child: ScreenUtilInit(
              designSize: const Size(1440, 900),
              builder: (context, _) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 1200),
                      textScaler: const TextScaler.linear(1.6),
                    ),
                    child: banner,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in [AppStrings.closeShift, AppStrings.recordExpense]) {
          final rect = tester.getRect(find.widgetWithText(AppButton, label));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
