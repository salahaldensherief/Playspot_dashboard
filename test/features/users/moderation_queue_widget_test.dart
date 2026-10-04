import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/users/data/datasources/moderation_remote_data_source.dart';
import 'package:play_spot_dashboard/features/users/presentation/cubit/moderation_cubit.dart';
import 'package:play_spot_dashboard/features/users/presentation/widgets/super_admin_ban_queue_section.dart';
import '../../support/local_translations_loader.dart';

class _Source extends Mock implements ModerationRemoteDataSource {}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets(
    'failed review queue displays failure and retry, never a false empty state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final source = _Source();
      when(() => source.getPendingBanRequests()).thenThrow(
        const PostgrestException(message: 'secret schema', code: 'PGRST202'),
      );
      final cubit = ModerationCubit(dataSource: source);
      addTearDown(cubit.close);
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
              home: BlocProvider<ModerationCubit>.value(
                value: cubit,
                child: const Scaffold(body: SuperAdminBanQueueSection()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('moderation_service_unavailable'.tr()), findsWidgets);
      expect(find.text('secret schema'), findsNothing);
      expect(find.text('no_pending_ban_requests'.tr()), findsNothing);
      when(() => source.getPendingBanRequests()).thenAnswer((_) async => []);
      await tester.tap(find.widgetWithText(TextButton, 'retry'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('moderation_service_unavailable'.tr()), findsNothing);
      expect(find.text('no_pending_ban_requests'.tr()), findsOneWidget);
      verify(() => source.getPendingBanRequests()).called(2);
      expect(tester.takeException(), isNull);
    },
  );
}
