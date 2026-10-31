import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_cubit.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_state.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/pages/kyc_reviews_page.dart';
import '../../support/local_translations_loader.dart';

class _Kyc extends Mock implements KycCubit {}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets('mounted KYC switches all labels without reloading reviews', (
    tester,
  ) async {
    final cubit = _Kyc();
    when(
      () => cubit.state,
    ).thenReturn(const KycState(status: KycStatus.success));
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.loadPendingReviews()).thenAnswer((_) async {});
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        startLocale: const Locale('en'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const LocalTranslationsLoader(),
        child: ScreenUtilInit(
          designSize: const Size(1440, 900),
          builder: (context, _) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: BlocProvider<KycCubit>.value(
              value: cubit,
              child: const Scaffold(body: KycReviewsPage()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('KYC Reviews'), findsOneWidget);
    final element = tester.element(find.byType(KycReviewsPage));
    await element.setLocale(const Locale('ar'));
    await tester.pumpAndSettle();
    expect(find.text('KYC Reviews'), findsNothing);
    expect(find.text('kyc_reviews'.tr()), findsOneWidget);
    expect(find.text('No pending KYC reviews at the moment.'), findsNothing);
    expect(find.text('no_kyc_pending'.tr()), findsOneWidget);
    expect(tester.element(find.byType(KycReviewsPage)), same(element));
    verify(() => cubit.loadPendingReviews()).called(1);
    expect(tester.takeException(), isNull);
  });
}
