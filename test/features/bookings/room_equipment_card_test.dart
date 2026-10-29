import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_equipment_artwork.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_card.dart';
import '../../support/local_translations_loader.dart';
import '../../../tool/equipment_cards_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final loader = FontLoader('Tajawal')
      ..addFont(rootBundle.load('assets/fonts/Tajawal/Tajawal-Regular.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final type in [
      'console',
      'pc',
      'billiards',
      'table_tennis',
      'vr',
      'simulator',
      'generic',
    ]) {
      final loader = SvgAssetLoader('assets/equipment/equipment-$type.svg');
      await svg.cache.putIfAbsent(
        loader.cacheKey(null),
        () => loader.loadBytes(null),
      );
    }
  });
  test(
    'equipment follows structured category and unknown/mixed has neutral fallback',
    () {
      expect(equipmentArtworkKey(fixtureRoom(0)), 'console');
      expect(equipmentArtworkKey(fixtureRoom(1)), 'pc');
      expect(equipmentArtworkKey(fixtureRoom(2)), 'billiards');
      expect(equipmentArtworkKey(fixtureRoom(3)), 'table_tennis');
      expect(equipmentArtworkKey(fixtureRoom(4)), 'vr');
      expect(equipmentArtworkKey(fixtureRoom(5)), 'simulator');
      expect(equipmentArtworkKey(fixtureRoom(6)), 'generic');
    },
  );
  for (final language in ['ar', 'en']) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('equipment cards $language width $width and failed close', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            startLocale: Locale(language),
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: const LocalTranslationsLoader(),
            child: RepaintBoundary(
              key: Key('preview'),
              child: EquipmentPreview(textScale: width < 500 ? 1.4 : 1),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.element(find.byType(Scaffold)).setLocale(Locale(language));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.byType(RoomEquipmentArtwork), findsNWidgets(7));
        expect(
          Directionality.of(
            tester.element(find.byType(RoomOccupancyCard).first),
          ),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        await expectLater(
          find.byKey(const Key('preview')),
          matchesGoldenFile(
            'goldens/equipment_${language}_${width.toInt()}.png',
          ),
        );
        await tester.tap(find.byIcon(Icons.price_check_rounded).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Fixture: operation not confirmed'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  for (final count in [6, 20, 40]) {
    testWidgets('renders $count rooms with stale controls blocked', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: const Locale('en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const LocalTranslationsLoader(),
          child: EquipmentPreview(stationCount: count, isStale: true),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(RoomOccupancyCard), findsNWidgets(count));
      expect(
        tester
            .widgetList<ExcludeFocus>(find.byType(ExcludeFocus))
            .where((w) => w.excluding)
            .length,
        greaterThanOrEqualTo(count),
      );
      await tester.tap(
        find.byIcon(Icons.price_check_rounded).first,
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.text('Fixture: operation not confirmed'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
