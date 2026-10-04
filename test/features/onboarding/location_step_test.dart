import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/entities/lounge_draft_params.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/widgets/location_step.dart';
import '../../support/local_translations_loader.dart';

class _Location implements LocationService {
  final pending = Completer<Position?>();
  int calls = 0;
  @override
  Future<Position?> getCurrentPosition() {
    calls++;
    return pending.future;
  }

  @override
  Future<bool> checkPermissions() async => false;
  @override
  Future<String?> getCityFromPosition(Position p, BuildContext c) async => null;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  test('invalid manual coordinates clear the restored pair explicitly', () {
    const draft = LoungeDraftParams(lat: 30, lng: 31, name: 'Venue');
    final cleared = draft.copyWith(clearCoordinates: true);
    expect(cleared.lat, isNull);
    expect(cleared.lng, isNull);
    expect(cleared.name, 'Venue');
    expect(draft.copyWith(city: 'Cairo').lat, 30);
  });

  Future<void> mount(
    WidgetTester tester,
    _Location location, {
    double? latitude,
    double? longitude,
    void Function(double?, double?)? changed,
  }) async {
    sl.registerSingleton<LocationService>(location);
    addTearDown(() => sl.unregister<LocationService>());
    final city = TextEditingController(text: 'Venue city');
    final address = TextEditingController(text: 'Venue address');
    addTearDown(city.dispose);
    addTearDown(address.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        path: 'assets/translations',
        assetLoader: const LocalTranslationsLoader(),
        saveLocale: false,
        child: ScreenUtilInit(
          designSize: const Size(1440, 900),
          builder: (context, _) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(
              body: SingleChildScrollView(
                child: LocationStep(
                  cityController: city,
                  addressController: address,
                  initialLatitude: latitude,
                  initialLongitude: longitude,
                  onCoordinatesDetected: changed,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('restored coordinates do not request current-device GPS', (
    tester,
  ) async {
    final location = _Location();
    await mount(tester, location, latitude: 30, longitude: 31);
    await tester.pumpAndSettle();
    expect(location.calls, 0);
    expect(find.text('30.0'), findsOneWidget);
    expect(find.text('31.0'), findsOneWidget);
    expect(find.text('Use current location'), findsOneWidget);
  });

  testWidgets(
    'manual edits survive late GPS and invalid edits clear authority',
    (tester) async {
      final location = _Location();
      final changes = <List<double?>>[];
      await mount(tester, location, changed: (a, b) => changes.add([a, b]));
      await tester.pump(const Duration(milliseconds: 100));
      final latitude = find.descendant(
        of: find.byKey(const ValueKey('venue-latitude')),
        matching: find.byType(TextField),
      );
      final longitude = find.descendant(
        of: find.byKey(const ValueKey('venue-longitude')),
        matching: find.byType(TextField),
      );
      await tester.enterText(latitude, '30.0444');
      await tester.enterText(longitude, '31.2357');
      expect(changes.last, [30.0444, 31.2357]);
      location.pending.complete(null);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Coordinates saved. Confirm they match the venue\'s location.',
        ),
        findsOneWidget,
      );
      await tester.enterText(latitude, '91');
      await tester.pump();
      expect(changes.last, [null, null]);
      await tester.enterText(latitude, 'NaN');
      expect(changes.last, [null, null]);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('GPS response after leaving the step does not call setState', (
    tester,
  ) async {
    final location = _Location();
    await mount(tester, location);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    location.pending.complete(null);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
