import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_state.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/dashboard_header.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/dashboard_time_range_selector.dart';
import '../../support/local_translations_loader.dart';

class _DashboardCubit extends Mock implements DashboardCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final width in [360.0, 700.0, 1100.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('dashboard header fits at $width with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final dashboard = _DashboardCubit();
        when(
          () => dashboard.state,
        ).thenReturn(const DashboardState(status: FeatureStatus.success));
        when(() => dashboard.stream).thenAnswer((_) => const Stream.empty());
        var refreshes = 0;

        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            startLocale: const Locale('ar'),
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: const LocalTranslationsLoader(),
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              minTextAdapt: true,
              builder: (context, child) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    body: BlocProvider<DashboardCubit>.value(
                      value: dashboard,
                      child: DashboardHeader(
                        isSuperAdmin: false,
                        onRefresh: () async {
                          refreshes++;
                        },
                        trailing: DashboardTimeRangeSelector(
                          selectedRange: DashboardTimeRange.week,
                          onRangeChanged: (_) {},
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
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(DashboardTimeRangeSelector), findsOneWidget);
        final rangeActions = find.descendant(
          of: find.byType(DashboardTimeRangeSelector),
          matching: find.byType(InkWell),
        );
        expect(rangeActions, findsNWidgets(3));
        for (var index = 0; index < 3; index++) {
          expect(
            tester.getSize(rangeActions.at(index)).height,
            greaterThanOrEqualTo(48),
          );
        }
        expect(find.byTooltip('تحديث البيانات'), findsOneWidget);
        final selectorTop = tester
            .getTopLeft(find.byType(DashboardTimeRangeSelector))
            .dy;
        final refreshBottom = tester
            .getBottomLeft(find.byTooltip('تحديث البيانات'))
            .dy;
        if (width <= 700) {
          expect(selectorTop, greaterThan(refreshBottom));
        }
        await tester.tap(find.byTooltip('تحديث البيانات'));
        expect(refreshes, 1);
      });
    }
  }
}
