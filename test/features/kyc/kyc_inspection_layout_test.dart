import 'dart:io';
import 'dart:ui' as ui;
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/kyc/domain/entities/kyc_request.dart';
import 'package:play_spot_dashboard/features/kyc/domain/repositories/kyc_repository.dart';
import 'package:play_spot_dashboard/features/kyc/domain/usecases/kyc_usecases.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_cubit.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/widgets/kyc_inspection_dialog.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/widgets/kyc_snapshot_details.dart';
import '../../support/local_translations_loader.dart';

class _Repository extends Mock implements KycRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final font = FontLoader('Tajawal')
      ..addFont(rootBundle.load('assets/fonts/Tajawal/Tajawal-Regular.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  const request = KycRequest(
    submissionId: 'review-1',
    revision: 3,
    loungeId: 'lounge-1',
    userId: 'owner-1',
    ownerName: 'محمد أحمد',
    ownerEmail: 'owner@example.invalid',
    loungeName: 'PlaySpot القاهرة',
    idDocumentUrl: '',
    snapshot: {
      'lounge': {
        'name': 'PlaySpot القاهرة',
        'city': 'القاهرة',
        'address': 'شارع التحرير، القاهرة',
        'contact_phone': '01012345678',
        'opening_time': '10:00',
        'closing_time': '02:00',
        'instapay_account': 'playspot@instapay',
        'description_ar': 'صالة ألعاب وترفيه',
      },
      'rooms': [
        {
          'name_ar': 'غرفة بلايستيشن ٥',
          'name_en': 'PlayStation 5 room',
          'max_capacity': 4,
          'hourly_rate_single': 123.75,
          'hourly_rate_multi': 175.5,
        },
      ],
      'extras': [
        {'name_ar': 'مياه', 'name_en': 'Water', 'price': 15},
      ],
    },
  );
  for (final width in [360.0, 600.0, 768.0, 1024.0, 1440.0]) {
    for (final language in ['ar', 'en']) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('KYC inspection $language $width text $scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = _Repository();
          when(
            () => repository.getPendingReviews(),
          ).thenAnswer((_) async => const Right([]));
          final cubit = KycCubit(
            submitKycUseCase: SubmitKycUseCase(repository),
            getPendingKycReviewsUseCase: GetPendingKycReviewsUseCase(
              repository,
            ),
            reviewKycUseCase: ReviewKycUseCase(repository),
          );
          addTearDown(cubit.close);
          final captureKey = GlobalKey();
          await tester.pumpWidget(
            EasyLocalization(
              supportedLocales: const [Locale('ar'), Locale('en')],
              startLocale: Locale(language),
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
                      key: captureKey,
                      child: Scaffold(
                        body: KycInspectionDialog(
                          request: request,
                          cubit: cubit,
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
          final context = tester.element(find.byType(KycSnapshotDetails));
          expect(
            Directionality.of(context),
            language == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          );
          expect(find.text('playspot@instapay'), findsOneWidget);
          expect(find.textContaining('123.75'), findsOneWidget);
          expect(find.textContaining('kyc_snapshot.'), findsNothing);
          final data = await tester.runAsync(() async {
            final boundary =
                captureKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final capture = await boundary.toImage(pixelRatio: 1);
            final bytes = await capture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            capture.dispose();
            return bytes;
          });
          if (data != null) {
            final file = File(
              'C:/Users/salah/Documents/Codex/2026-09-30/playspot-chatgpt-remotes-git-fetch-origin/outputs/kyc-screenshots/inspection-$language-${width.toInt()}-$scale.png',
            );
            file.parent.createSync(recursive: true);
            file.writeAsBytesSync(data.buffer.asUint8List());
          }
        });
      }
    }
  }
}
