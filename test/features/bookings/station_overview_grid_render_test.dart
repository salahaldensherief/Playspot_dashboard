import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/station_operational_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/station_overview_grid.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

import '../../support/local_translations_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final language in ['en', 'ar']) {
    testWidgets('station cards paint their content in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stations = List.generate(6, (index) {
        final room = RoomEntity(
          id: 'station-$index',
          loungeId: 'lounge',
          nameAr: 'جهاز $index',
          nameEn: 'Station $index',
          isAvailable: true,
          images: const [],
          featuresAr: const [],
          featuresEn: const [],
          resourceType: index.isEven ? 'pc' : 'playstation',
          status: RoomStatusEnum.available,
        );
        return StationOperationalState(
          room: room,
          active: null,
          pending: null,
          next: null,
          activeBookingCount: 0,
          attentionRequests: 0,
          roomDataFresh: true,
        );
      });

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(language),
          fallbackLocale: const Locale('en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const LocalTranslationsLoader(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                body: StationOverviewGrid(stations: stations, onManage: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(language == 'ar' ? 'جهاز 0' : 'Station 0'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('station_station-0')), findsOneWidget);
    });
  }
}
