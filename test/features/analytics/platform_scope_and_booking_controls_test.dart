import 'package:flutter/services.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/dashboard_time_range_selector.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/super_admin_dashboard_view.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_state.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_dialog.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/art_core/layouts/top_bar/top_bar_branch_switcher.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_extras_section.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_play_mode_selector.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_booking_room_selector.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import 'package:play_spot_dashboard/features/kyc/data/datasources/kyc_remote_data_source.dart';
import 'package:play_spot_dashboard/features/kyc/data/repositories/kyc_repository_impl.dart';
import '../../support/local_translations_loader.dart';

class _Login extends Mock implements LoginCubit {}

class _Dashboard extends Mock implements DashboardCubit {}

class _Requests extends Mock implements ClientRequestsCubit {}

class _Bookings extends Mock implements BookingCubit {}

class _Rooms extends Mock implements RoomCubit {}

class _KycSource extends Mock implements KycRemoteDataSource {}

const room = RoomEntity(
  id: 'room',
  loungeId: 'lounge',
  nameAr: 'غرفة الألعاب',
  nameEn: 'Gaming room',
  hourlyRateSingle: 60,
  hourlyRateMulti: 80,
  isAvailable: true,
  images: [],
  featuresAr: [],
  featuresEn: [],
);

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

  test(
    'missing review RPC is a failure, never an empty review queue',
    () async {
      final source = _KycSource();
      when(source.getPendingReviews).thenThrow(
        const PostgrestException(message: 'missing function', code: 'PGRST202'),
      );
      final result = await KycRepositoryImpl(source).getPendingReviews();
      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure.message, 'kyc_review_service_unavailable'),
        (_) => fail('Missing backend must not succeed'),
      );
    },
  );

  testWidgets('super admin cannot implicitly acquire a first lounge badge', (
    tester,
  ) async {
    final login = _Login();
    when(() => login.state).thenReturn(
      const LoginState(
        user: UserEntity(
          id: 'platform',
          email: 'fixture@example.invalid',
          name: 'Super Admin',
          role: UserRole.superAdmin,
          loungeId: 'stale-owner-lounge',
        ),
      ),
    );
    when(() => login.stream).thenAnswer((_) => const Stream.empty());
    // No LoungeCubit is provided: a platform header must not consume its scope.
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<LoginCubit>.value(
          value: login,
          child: const TopBarBranchSwitcher(),
        ),
      ),
    );
    expect(find.text('stale-owner-lounge'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['ar', 'en']) {
    for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('booking controls $language $width text $scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final rooms = _Rooms();
          when(() => rooms.state).thenReturn(const RoomState(rooms: [room]));
          when(() => rooms.stream).thenAnswer((_) => const Stream.empty());
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
                  theme: ThemeData.dark().copyWith(
                    textTheme: ThemeData.dark().textTheme.apply(
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 1000),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Scaffold(
                      body: Padding(
                        padding: const EdgeInsets.all(16),
                        child: BlocProvider<RoomCubit>.value(
                          value: rooms,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AddBookingRoomSelector(
                                  selectedRoom: null,
                                  onRoomSelected: (_) {},
                                ),
                                AddBookingPlayModeSelector(
                                  room: null,
                                  selectedMode: 'single',
                                  onModeChanged: (_) {},
                                ),
                                AddBookingPlayModeSelector(
                                  room: room,
                                  selectedMode: 'single',
                                  onModeChanged: (_) {},
                                ),
                                AddBookingExtrasSection(
                                  loungeId: 'lounge',
                                  selectedExtras: const [],
                                  onExtrasChanged: (_) {},
                                ),
                                AppButton(
                                  text: language == 'ar'
                                      ? 'حجز تفصيلي جديد'
                                      : 'Detailed booking',
                                  icon: Icons.add,
                                  height: 20,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          final dropdown = tester.widget<DropdownButton<RoomEntity>>(
            find.byType(DropdownButton<RoomEntity>),
          );
          expect(dropdown.value, isNull);
          expect(find.textContaining('(0 '), findsNothing);
          expect(find.textContaining('(60 '), findsOneWidget);
          expect(find.textContaining('(80 '), findsOneWidget);
          expect(
            tester.getSize(find.byType(ElevatedButton).last).height,
            greaterThanOrEqualTo(48),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  for (final language in ['ar', 'en']) {
    for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('detailed booking dialog $language $width text $scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final capture = GlobalKey();
          final bookings = _Bookings();
          when(
            () => bookings.state,
          ).thenReturn(const BookingState(selectedDurationMinutes: 60));
          when(() => bookings.stream).thenAnswer((_) => const Stream.empty());
          when(() => bookings.updateSelectedDuration(any())).thenReturn(null);
          final rooms = _Rooms();
          when(() => rooms.state).thenReturn(const RoomState(rooms: [room]));
          when(() => rooms.stream).thenAnswer((_) => const Stream.empty());
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
                  theme: ThemeData.dark().copyWith(
                    textTheme: ThemeData.dark().textTheme.apply(
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 1000),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Scaffold(
                      body: RepaintBoundary(
                        key: capture,
                        child: MultiBlocProvider(
                          providers: [
                            BlocProvider<RoomCubit>.value(value: rooms),
                            BlocProvider<BookingCubit>.value(value: bookings),
                          ],
                          child: const AddBookingDialog(
                            loungeId: 'lounge',
                            initialRoom: room,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.textContaining('(0 '), findsNothing);
          expect(find.textContaining('(60 '), findsOneWidget);
          expect(find.textContaining('(80 '), findsOneWidget);
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -700),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          final directory = Platform.environment['PLAYSPOT_SCREENSHOT_DIR'];
          if (directory != null) {
            await tester.runAsync(() async {
              final image =
                  await (capture.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 1);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(directory).create(recursive: true);
              await File(
                '$directory/detailed-${width.toInt()}-$language-$scale.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  for (final language in ['ar', 'en']) {
    for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('platform dashboard $language $width text $scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final capture = GlobalKey();
          final dashboard = _Dashboard();
          when(() => dashboard.state).thenReturn(
            const DashboardState(
              status: FeatureStatus.success,
              totalLounges: 5,
              totalUsers: 120,
              totalBookings: 80,
              totalRevenue: 14000,
              revenueChart: [
                {'day': '2026-10-01', 'revenue': 900},
                {'day': '2026-10-02', 'revenue': 1200},
              ],
              topLounges: [
                {
                  'lounge_name': 'صالة الألعاب PlaySpot',
                  'total_revenue': 1200,
                  'bookings_count': 12,
                },
              ],
            ),
          );
          when(() => dashboard.stream).thenAnswer((_) => const Stream.empty());
          final requests = _Requests();
          when(() => requests.state).thenReturn(const ClientRequestsState());
          when(() => requests.stream).thenAnswer((_) => const Stream.empty());
          final bookings = _Bookings();
          when(
            () => bookings.state,
          ).thenReturn(const BookingState(selectedDurationMinutes: 60));
          when(() => bookings.stream).thenAnswer((_) => const Stream.empty());
          when(() => bookings.updateSelectedDuration(any())).thenReturn(null);
          final rooms = _Rooms();
          when(() => rooms.state).thenReturn(const RoomState(rooms: [room]));
          when(() => rooms.stream).thenAnswer((_) => const Stream.empty());
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
                  theme: ThemeData.dark().copyWith(
                    textTheme: ThemeData.dark().textTheme.apply(
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 1000),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Scaffold(
                      body: RepaintBoundary(
                        key: capture,
                        child: MultiBlocProvider(
                          providers: [
                            BlocProvider<DashboardCubit>.value(
                              value: dashboard,
                            ),
                            BlocProvider<ClientRequestsCubit>.value(
                              value: requests,
                            ),
                            BlocProvider<BookingCubit>.value(value: bookings),
                          ],
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: SuperAdminDashboardView(
                              timeRange: DashboardTimeRange.week,
                              onTimeRangeChanged: _ignoreRange,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.text('sybar'), findsNothing);
          expect(find.textContaining('14000'), findsWidgets);
          expect(tester.takeException(), isNull);
          final directory = Platform.environment['PLAYSPOT_SCREENSHOT_DIR'];
          if (directory != null) {
            await tester.runAsync(() async {
              final image =
                  await (capture.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 1);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(directory).create(recursive: true);
              await File(
                '$directory/platform-${width.toInt()}-$language-$scale.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
}

void _ignoreRange(DashboardTimeRange range) {}
