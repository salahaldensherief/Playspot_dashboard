import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/art_core/widgets/stat_card.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_state.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/lounge_stats_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/lounge_stats_state.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/cockpit_kpi_grid.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import '../../support/local_translations_loader.dart';

class _DashboardCubit extends Mock implements DashboardCubit {}

class _LoungeStatsCubit extends Mock implements LoungeStatsCubit {}

class _BookingCubit extends Mock implements BookingCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final width in [360.0, 1440.0]) {
    testWidgets('super admin KPI loading preserves card positions at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dashboard = _DashboardCubit();
      when(() => dashboard.stream).thenAnswer((_) => const Stream.empty());

      Future<void> show(FeatureStatus status) async {
        when(() => dashboard.state).thenReturn(DashboardState(status: status));
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            startLocale: const Locale('ar'),
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: const LocalTranslationsLoader(),
            child: ScreenUtilInit(
              designSize: Size(width, 900),
              builder: (context, child) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: BlocProvider<DashboardCubit>.value(
                    value: dashboard,
                    child: const CockpitKpiGrid(isSuperAdmin: true),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      await show(FeatureStatus.loading);
      expect(tester.takeException(), isNull);
      expect(find.byType(ShimmerLoading), findsNWidgets(4));
      final loadingTops = [
        for (final element in find.byType(ShimmerLoading).evaluate())
          tester.getTopLeft(find.byElementPredicate((e) => e == element)).dy,
      ];

      await tester.pumpWidget(const SizedBox.shrink());
      await show(FeatureStatus.success);
      expect(tester.takeException(), isNull);
      expect(find.byType(StatCard), findsNWidgets(4));
      final loadedTops = [
        for (final element in find.byType(StatCard).evaluate())
          tester.getTopLeft(find.byElementPredicate((e) => e == element)).dy,
      ];
      expect(loadedTops, loadingTops);
    });
  }

  testWidgets('lounge KPI loading renders six responsive placeholders', (
    tester,
  ) async {
    final dashboard = _DashboardCubit();
    final stats = _LoungeStatsCubit();
    final bookings = _BookingCubit();
    when(() => dashboard.state).thenReturn(const DashboardState());
    when(
      () => stats.state,
    ).thenReturn(const LoungeStatsState(status: LoungeStatsStatus.loading));
    when(() => bookings.state).thenReturn(const BookingState());
    when(() => dashboard.stream).thenAnswer((_) => const Stream.empty());
    when(() => stats.stream).thenAnswer((_) => const Stream.empty());
    when(() => bookings.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DashboardCubit>.value(value: dashboard),
              BlocProvider<LoungeStatsCubit>.value(value: stats),
              BlocProvider<BookingCubit>.value(value: bookings),
            ],
            child: const Scaffold(body: CockpitKpiGrid()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ShimmerLoading), findsNWidgets(6));
  });
}
