import 'dart:convert';
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
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_state.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/lounge_stats_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/lounge_stats_state.dart';
import 'package:play_spot_dashboard/features/analytics/domain/entities/lounge_stats_entity.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/lounge_dashboard_sections.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';

class _Login extends Mock implements LoginCubit {}

class _Bookings extends Mock implements BookingCubit {}

class _Dashboard extends Mock implements DashboardCubit {}

class _Stats extends Mock implements LoungeStatsCubit {}

class _Rooms extends Mock implements RoomCubit {}

class _Requests extends Mock implements ClientRequestsCubit {}

class _Shift extends Mock implements ShiftCubit {}

class _Translations extends AssetLoader {
  static final data = <String, Map<String, dynamic>>{};
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      data[locale.languageCode]!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final locale in ['ar', 'en']) {
      _Translations.data[locale] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$locale.json'),
              )
              as Map<String, dynamic>;
    }
    final fonts = FontLoader('Tajawal')
      ..addFont(rootBundle.load('assets/fonts/Tajawal/Tajawal-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Tajawal/Tajawal-Bold.ttf'));
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('actual lounge dashboard RTL at $width with text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1024);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final login = _Login();
        when(() => login.state).thenReturn(
          const LoginState(
            user: UserEntity(
              id: 'fixture-owner',
              email: 'fixture@example.invalid',
              name: 'مالك الصالة',
              role: UserRole.owner,
              loungeId: 'fixture-lounge',
            ),
          ),
        );
        when(() => login.stream).thenAnswer((_) => const Stream.empty());
        final bookings = _Bookings();
        when(
          () => bookings.state,
        ).thenReturn(const BookingState(status: BookingStatusState.success));
        when(() => bookings.stream).thenAnswer((_) => const Stream.empty());
        final dashboard = _Dashboard();
        when(
          () => dashboard.state,
        ).thenReturn(const DashboardState(status: FeatureStatus.success));
        when(() => dashboard.stream).thenAnswer((_) => const Stream.empty());
        final stats = _Stats();
        when(() => stats.state).thenReturn(
          const LoungeStatsState(
            status: LoungeStatsStatus.success,
            stats: LoungeStatsEntity(
              success: true,
              loungeId: 'fixture-lounge',
              todayRevenue: 0,
              monthlyRevenue: 0,
              totalRooms: 7,
              occupiedRooms: 0,
              occupancyRate: 0,
              activeBookings: 0,
              openShifts: 0,
              lowStockItems: 0,
            ),
          ),
        );
        when(() => stats.stream).thenAnswer((_) => const Stream.empty());
        final rooms = _Rooms();
        when(() => rooms.state).thenReturn(
          RoomState(
            status: RoomStatus.success,
            rooms: [
              for (var i = 1; i <= 7; i++)
                RoomEntity(
                  id: 'room-$i',
                  loungeId: 'fixture-lounge',
                  nameAr: 'غرفة $i',
                  nameEn: 'Room $i',
                  isAvailable: i != 3,
                  images: const [],
                  featuresAr: const [],
                  featuresEn: const [],
                  status: i == 3
                      ? RoomStatusEnum.maintenance
                      : RoomStatusEnum.available,
                ),
            ],
          ),
        );
        when(() => rooms.stream).thenAnswer((_) => const Stream.empty());
        final requests = _Requests();
        when(() => requests.state).thenReturn(
          const ClientRequestsState(status: ClientRequestsStatus.success),
        );
        when(() => requests.stream).thenAnswer((_) => const Stream.empty());
        final shifts = _Shift();
        when(
          () => shifts.state,
        ).thenReturn(const ShiftState(status: ShiftStatus.initial));
        when(() => shifts.stream).thenAnswer((_) => const Stream.empty());
        final capture = GlobalKey();
        final design = width < 600
            ? const Size(390, 844)
            : width < 1024
            ? const Size(768, 1024)
            : const Size(1440, 1024);
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            startLocale: const Locale('ar'),
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: _Translations(),
            child: Builder(
              builder: (context) => ScreenUtilInit(
                designSize: design,
                minTextAdapt: true,
                builder: (context, child) => MaterialApp(
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  theme: ThemeData(
                    brightness: Brightness.dark,
                    fontFamily: 'Tajawal',
                    scaffoldBackgroundColor: AppColors.scaffoldBackground,
                  ),
                  home: MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: MultiBlocProvider(
                      providers: [
                        BlocProvider<LoginCubit>.value(value: login),
                        BlocProvider<BookingCubit>.value(value: bookings),
                        BlocProvider<DashboardCubit>.value(value: dashboard),
                        BlocProvider<LoungeStatsCubit>.value(value: stats),
                        BlocProvider<RoomCubit>.value(value: rooms),
                        BlocProvider<ClientRequestsCubit>.value(
                          value: requests,
                        ),
                        BlocProvider<ShiftCubit>.value(value: shifts),
                      ],
                      child: Scaffold(
                        body: SingleChildScrollView(
                          child: RepaintBoundary(
                            key: capture,
                            child: ColoredBox(
                              color: AppColors.scaffoldBackground,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: LoungeDashboardSections(
                                  onRefresh: () {},
                                ),
                              ),
                            ),
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
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(
            tester.element(find.byType(LoungeDashboardSections)),
          ),
          ui.TextDirection.rtl,
        );
        expect(find.text('VIP 01'), findsNothing);
        expect(find.text('35%'), findsNothing);
        expect(find.byType(Switch), findsNothing);
        expect(find.text('غرفة 3'), findsOneWidget);
        final output = Platform.environment['PLAYSPOT_SCREENSHOT_DIR'];
        if (output != null) {
          await tester.runAsync(() async {
            final boundary =
                capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final dir = Directory(output);
            await dir.create(recursive: true);
            await File(
              '${dir.path}/dashboard-rtl-${width.toInt()}-text-$scale.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
