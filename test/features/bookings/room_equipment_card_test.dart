import 'dart:io' show Platform;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/bookings_collapsible_occupancy.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_grid.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_session_timer.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_clock_host.dart';
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
        // Font rasterization differs across hosts. The required Windows CI job
        // uses the same Flutter version as these reviewed Windows references.
        // Layout, semantics and interaction assertions still run on every host.
        if (Platform.isWindows) {
          await expectLater(
            find.byKey(const Key('preview')),
            matchesGoldenFile(
              'goldens/equipment_${language}_${width.toInt()}.png',
            ),
          );
        }
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

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'operational map refresh, failure, retry and keyboard at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1600);
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
            child: EquipmentPreview(
              operational: true,
              textScale: width < 500 ? 1.6 : 1,
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(BookingsCollapsibleOccupancy), findsOneWidget);
        expect(find.byType(RoomOccupancyGrid), findsOneWidget);
        expect(find.byType(RoomOccupancyCard), findsNWidgets(7));
        expect(tester.takeException(), isNull);
        if (width > 500) {
          final sizes = find
              .byType(RoomOccupancyCard)
              .evaluate()
              .take(4)
              .map((e) => tester.getSize(find.byWidget(e.widget)).height)
              .toList();
          expect(sizes.toSet().length, 1);
        }
        final closeIcon = find.byIcon(Icons.price_check_rounded).first;
        final buttonFocus = Focus.of(tester.element(closeIcon));
        buttonFocus.requestFocus();
        await tester.pump();
        expect(buttonFocus.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Fixture: operation not confirmed'), findsOneWidget);

        final rooms =
            tester.element(find.byType(RoomOccupancyGrid)).read<RoomCubit>()
                as FixtureRooms;
        rooms.setStatus(RoomStatus.loading);
        await tester.pump();
        expect(find.byType(LinearProgressIndicator), findsNWidgets(7));
        expect(buttonFocus.hasFocus, isFalse);
        rooms.setStatus(RoomStatus.failure);
        await tester.pump();
        final refreshes = rooms.refreshes;
        await tester.tap(find.widgetWithIcon(TextButton, Icons.refresh).first);
        await tester.pump();
        expect(rooms.refreshes, refreshes + 1);
        expect(tester.takeException(), isNull);
        rooms.setStatus(RoomStatus.success);
        await tester.pump();
        expect(find.byType(LinearProgressIndicator), findsNothing);
        final bookings =
            tester.element(find.byType(RoomOccupancyGrid)).read<BookingCubit>()
                as FixtureBookings;
        // Preserve the same booking list: status-only stream transitions must
        // rebuild the actual operational grid and block stale session controls.
        for (final status in [
          BookingStatusState.initial,
          BookingStatusState.loading,
        ]) {
          bookings.setStatus(status);
          await tester.pump();
          expect(find.byType(LinearProgressIndicator), findsNWidgets(7));
          expect(
            tester
                .widgetList<RoomOccupancyCard>(find.byType(RoomOccupancyCard))
                .every((card) => card.isRefreshing),
            isTrue,
          );
        }
        bookings.setStatus(BookingStatusState.failure);
        await tester.pump();
        expect(
          tester
              .widgetList<RoomOccupancyCard>(find.byType(RoomOccupancyCard))
              .every((card) => card.isStale),
          isTrue,
        );
        final attempts = bookings.attempts;
        await tester.tap(closeIcon, warnIfMissed: false);
        await tester.pump();
        expect(bookings.attempts, attempts);
        final bookingRefreshes = bookings.refreshes;
        await tester.tap(find.widgetWithIcon(TextButton, Icons.refresh).first);
        await tester.pump();
        expect(bookings.refreshes, bookingRefreshes + 1);
        bookings.setStatus(BookingStatusState.success);
        await tester.pump();
        expect(
          tester
              .widgetList<RoomOccupancyCard>(find.byType(RoomOccupancyCard))
              .every((card) => !card.isStale && !card.isRefreshing),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'native timers follow the shared clock and preserve elapsed/remaining semantics',
    (tester) async {
      var now = fixtureNow;
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: const Locale('en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const LocalTranslationsLoader(),
          child: MaterialApp(
            home: SessionClockHost(
              clock: () => now,
              child: Scaffold(
                body: Column(
                  children: [
                    RoomSessionTimer(booking: fixtureBooking(0)),
                    RoomSessionTimer(booking: fixtureBooking(1)),
                    RoomSessionTimer(
                      booking: fixtureBooking(1).copyWith(
                        scheduledEndUtc: fixtureNow.subtract(
                          const Duration(minutes: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('43:00'), findsOneWidget);
      expect(find.text('17:00'), findsOneWidget);
      expect(find.text('-01:00'), findsOneWidget);
      now = now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('44:00'), findsOneWidget);
      expect(find.text('16:00'), findsOneWidget);
      expect(find.text('-02:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
