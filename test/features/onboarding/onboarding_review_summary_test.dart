import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/entities/lounge_draft_params.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/widgets/onboarding_review_summary.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import '../../support/local_translations_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final font in [
      FontLoader('Tajawal')
        ..addFont(rootBundle.load('assets/fonts/Tajawal/Tajawal-Regular.ttf')),
      FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')),
    ]) {
      await font.load();
    }
  });
  const state = OnboardingState(
    draft: LoungeDraftParams(
      step: 7,
      name: 'PlaySpot — صالة القاهرة',
      description: 'صالة ألعاب وترفيه',
      city: 'القاهرة',
      address: 'شارع التحرير، القاهرة',
      contactPhone: '01012345678',
      opensAt: '10:00',
      closesAt: '02:00',
    ),
    rooms: [
      RoomEntity(
        id: 'r1',
        loungeId: 'l1',
        nameAr: 'غرفة بلايستيشن ٥',
        nameEn: 'PlayStation 5 room',
        isAvailable: true,
        images: [],
        featuresAr: [],
        featuresEn: [],
        hourlyRateSingle: 123.75,
        hourlyRateMulti: 175.5,
        maxCapacity: 4,
      ),
    ],
  );

  for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
    for (final lang in ['ar', 'en']) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          'review $lang width $width text $scale requires explicit consent',
          (tester) async {
            tester.view.physicalSize = Size(width, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final key = GlobalKey();
            var confirmed = false;
            await tester.pumpWidget(
              EasyLocalization(
                supportedLocales: const [Locale('ar'), Locale('en')],
                startLocale: Locale(lang),
                saveLocale: false,
                path: 'assets/translations',
                assetLoader: const LocalTranslationsLoader(),
                child: Builder(
                  builder: (context) => ScreenUtilInit(
                    designSize: const Size(1920, 1080),
                    builder: (context, child) => MaterialApp(
                      locale: context.locale,
                      supportedLocales: context.supportedLocales,
                      localizationsDelegates: context.localizationDelegates,
                      theme: ThemeData.dark().copyWith(
                        textTheme: ThemeData.dark().textTheme.apply(
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.linear(scale)),
                        child: child ?? const SizedBox.shrink(),
                      ),
                      home: RepaintBoundary(
                        key: key,
                        child: Scaffold(
                          body: SafeArea(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: OnboardingReviewSummary(
                                state: state,
                                ownerName: 'محمد أحمد',
                                ownerEmail: 'owner@example.invalid',
                                hasMainImage: true,
                                hasIdentity: true,
                                hasBusinessDocument: false,
                                confirmed: false,
                                onConfirmed: (value) => confirmed = value,
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
            expect(confirmed, isFalse);
            expect(find.textContaining('123.75'), findsOneWidget);
            final context = tester.element(
              find.byType(OnboardingReviewSummary),
            );
            expect(
              Directionality.of(context),
              lang == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            );
            final bytes = await tester.runAsync(() async {
              final boundary =
                  key.currentContext?.findRenderObject()
                      as RenderRepaintBoundary;
              final capture = await boundary.toImage(pixelRatio: 1);
              final data = await capture.toByteData(
                format: ui.ImageByteFormat.png,
              );
              capture.dispose();
              return data;
            });
            if (bytes != null) {
              final file = File(
                'C:/Users/salah/Documents/Codex/2026-09-30/playspot-chatgpt-remotes-git-fetch-origin/outputs/screenshots/onboarding-review-$lang-${width.toInt()}-$scale.png',
              );
              file.parent.createSync(recursive: true);
              file.writeAsBytesSync(bytes.buffer.asUint8List());
            }
            await tester.ensureVisible(
              find.byKey(const ValueKey('onboarding-review-consent')),
            );
            await tester.tap(
              find.byKey(const ValueKey('onboarding-review-consent')),
            );
            await tester.pump();
            expect(confirmed, isTrue);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
