import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/cashier_sessions_workspace.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/cashier_session_details.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_operations_summary.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_clock_host.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_ticker.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';
import '../../support/local_translations_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 1, 15);
  final a = Booking(
    id: 'a',
    userId: 'u',
    loungeId: 'l',
    roomId: 'r',
    roomName: 'PlayStation 5 · غرفة ١',
    userName: 'محمد أحمد',
    userPhone: '01012345678',
    playMode: 'single',
    date: now,
    startTime: '${now.hour.toString().padLeft(2, '0')}:00',
    endTime: '23:00',
    status: BookingStatus.inProgress,
    totalPrice: 125,
    canteenOrders: const [
      {'id': 'order1'},
    ],
  );
  final b = a.copyWith(
    id: 'b',
    roomId: 'r2',
    roomName: 'بلياردو · طاولة ٢',
    userName: 'سارة محمود',
    isOpenTime: true,
    durationMinutes: 0,
  );
  final next = a.copyWith(
    id: 'next',
    startTime: '23:30',
    status: BookingStatus.upcoming,
  );
  final request = ClientRequestEntity(
    id: 'request',
    loungeId: 'l',
    bookingId: 'a',
    titleAr: 'طلب مساعدة',
    titleEn: 'Staff assistance',
    bodyAr: 'يرجى تغيير يد التحكم',
    bodyEn: 'Please replace the controller',
    type: ClientRequestType.callStaff,
    createdAt: now,
  );
  final captureKey = GlobalKey();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final font = FontLoader('Tajawal')
      ..addFont(rootBundle.load('assets/fonts/Tajawal/Tajawal-Regular.ttf'));
    await font.load();
  });

  Future<void> mount(
    WidgetTester tester,
    double width,
    String locale,
    double scale, {
    List<Booking>? bookings,
  }) async {
    final testStart = tester.binding.clock.now();
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      EasyLocalization(
        key: ValueKey('$width-$locale-$scale'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        startLocale: Locale(locale),
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const LocalTranslationsLoader(),
        child: Builder(
          builder: (context) => ScreenUtilInit(
            designSize: const Size(1920, 1080),
            builder: (context, child) => MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(
                  key: captureKey,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: ThemeData.dark().copyWith(
                scaffoldBackgroundColor: AppColors.scaffoldBackground,
                textTheme: ThemeData.dark().textTheme.apply(
                  fontFamily: 'Tajawal',
                ),
              ),
              home: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: SizedBox(
                    child: SessionClockHost(
                      clock: () => now.add(
                        tester.binding.clock.now().difference(testStart),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: CashierSessionsWorkspace(
                          bookings: bookings ?? [a, b, next],
                          requests: [request],
                          onManage: (_) {},
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
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    final directory = Platform.environment['PLAYSPOT_SCREENSHOT_DIR'];
    if (directory == null) return;
    final boundary =
        captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
    for (final locale in ['ar', 'en']) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('cashier $width $locale text=$scale', (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await mount(tester, width, locale, scale);
          expect(tester.takeException(), isNull);
          expect(find.text(a.roomName), findsWidgets);
          expect(find.text('starts_in'), findsNothing);
          expect(
            find.text(locale == 'ar' ? 'يبدأ خلال' : 'Starts in'),
            findsWidgets,
          );
          if (width >= 768) {
            expect(find.byType(CashierSessionDetails), findsOneWidget);
            expect(
              SessionTickerScope.nowOf(
                tester.element(find.byType(CashierSessionDetails)),
              ).hour,
              now.hour,
            );
          }
          await screenshot(tester, 'cashier-${width.toInt()}-$locale-$scale');
          if (width <= 600) {
            await tester.tap(find.text(a.roomName).first);
            await tester.pumpAndSettle();
            expect(find.byType(CashierSessionDetails), findsOneWidget);
            expect(tester.takeException(), isNull);
            await screenshot(
              tester,
              'cashier-${width.toInt()}-$locale-$scale-details',
            );
            await tester.tap(
              find.text(locale == 'ar' ? 'العودة للجلسات' : 'Back to sessions'),
            );
            await tester.pumpAndSettle();
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }

  testWidgets('clock ticks rebuild leaves, not the cashier workspace', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final many = List.generate(
      100,
      (i) => a.copyWith(id: 'stress-$i', roomName: 'Room $i'),
    );
    await mount(tester, 1440, 'ar', 1, bookings: many);
    final builds = <String, int>{};
    final original = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      final name = element.widget.runtimeType.toString();
      builds.update(name, (count) => count + 1, ifAbsent: () => 1);
    };
    final elapsed = Stopwatch()..start();
    try {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    } finally {
      debugOnRebuildDirtyWidget = original;
    }
    elapsed.stop();
    expect(builds['CashierSessionsWorkspace'] ?? 0, 0);
    expect(builds['CashierSessionDetails'] ?? 0, 0);
    expect(builds['SessionLiveClock'] ?? 0, greaterThan(0));
    final directory = Platform.environment['PLAYSPOT_SCREENSHOT_DIR'];
    if (directory != null) {
      File('$directory/dashboard-rebuild-measurement.json').writeAsStringSync(
        jsonEncode({
          'mode':
              'Flutter widget test, debug, Windows host; not device frame timings',
          'inputBookings': 100,
          'simulatedSeconds': 10,
          'hostElapsedMicroseconds': elapsed.elapsedMicroseconds,
          'builds': builds,
        }),
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('next resource booking conflict uses the loaded schedule', () {
    final overlapping = next.copyWith(startTime: a.startTime);
    expect(
      SessionOperationsSummary.fromBookings(a, [b, overlapping]).hasConflict,
      isTrue,
    );
    expect(
      SessionOperationsSummary.fromBookings(b, [a, next]).nextBooking,
      isNull,
    );
  });
}
