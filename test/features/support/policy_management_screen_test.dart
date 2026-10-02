import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/features/support/data/models/app_policy_model.dart';
import 'package:play_spot_dashboard/features/support/domain/entities/app_policy_entity.dart';
import 'package:play_spot_dashboard/features/support/presentation/policy_management_screen.dart';
import 'package:play_spot_dashboard/features/support/presentation/support_cubit.dart';
import 'package:play_spot_dashboard/features/support/presentation/support_state.dart';

class _Cubit extends Mock implements SupportCubit {}

class _Translations extends AssetLoader {
  const _Translations();
  static final data = <String, Map<String, dynamic>>{};
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      data[locale.languageCode]!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final language in ['ar', 'en']) {
      _Translations.data[language] =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/translations/$language.json',
                ),
              )
              as Map<String, dynamic>;
    }
  });

  for (final locale in ['ar', 'en']) {
    testWidgets(
      'policy load, missing tabs and drafts remain usable in $locale',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final stream = StreamController<SupportState>.broadcast();
        final cubit = _Cubit();
        var state = const SupportState();
        when(() => cubit.state).thenAnswer((_) => state);
        when(() => cubit.stream).thenAnswer((_) => stream.stream);
        when(() => cubit.loadPolicies()).thenAnswer((_) async {});
        addTearDown(stream.close);

        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            startLocale: Locale(locale),
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: const _Translations(),
            child: Builder(
              builder: (context) => ScreenUtilInit(
                designSize: const Size(1920, 1080),
                builder: (context, child) => MaterialApp(
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: BlocProvider<SupportCubit>.value(
                    value: cubit,
                    child: const PolicyManagementScreen(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        verify(() => cubit.loadPolicies()).called(1);

        final models = <AppPolicyModel>[
          const AppPolicyModel(
            id: 'terms_of_service',
            policyType: 'terms_of_service',
            titleAr: 'شروط محفوظة',
            titleEn: 'Stored terms',
            contentAr: 'نص محفوظ',
            contentEn: 'Stored content',
          ),
        ];
        state = SupportState(status: SupportStatus.success, policies: models);
        stream.add(state);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        List<String> texts() => tester
            .widgetList<TextField>(find.byType(TextField))
            .map((field) => field.controller!.text)
            .toList();
        expect(texts(), [
          'شروط محفوظة',
          'نص محفوظ',
          'Stored terms',
          'Stored content',
        ]);

        for (final label in [
          AppStrings.privacyPolicy,
          AppStrings.refundPolicy,
        ]) {
          await tester.tap(find.text(label).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(texts(), [label, '', label, '']);
        }

        await tester.enterText(find.byType(TextField).at(1), 'Unsaved draft');
        state = state.copyWith(actionStatus: SupportStatus.loading);
        stream.add(state);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(texts()[1], 'Unsaved draft');

        state = SupportState(
          status: SupportStatus.success,
          policies: <AppPolicyEntity>[],
        );
        stream.add(state);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(texts(), [
          AppStrings.refundPolicy,
          '',
          AppStrings.refundPolicy,
          '',
        ]);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
