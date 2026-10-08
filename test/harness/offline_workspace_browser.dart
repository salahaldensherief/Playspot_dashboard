// Isolated browser harness. Never targets a hosted project or real account.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/features/offline_cashier/offline_cashier_di.dart';
import 'package:play_spot_dashboard/features/offline_cashier/presentation/offline_workspace_cubit.dart';
import 'package:play_spot_dashboard/features/offline_cashier/presentation/offline_workspace_page.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

class FixtureLogin extends Cubit<LoginState> implements LoginCubit {
  FixtureLogin(UserEntity user) : super(LoginState(user: user));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Fixture stage: localization');
  await EasyLocalization.ensureInitialized();
  debugPrint('Fixture stage: authentication');
  const url = String.fromEnvironment('FIXTURE_URL');
  if (!url.startsWith('http://127.0.0.1:51463')) {
    throw StateError('Synthetic localhost only');
  }
  final client = SupabaseClient(url, 'synthetic-public-key');
  final preferences = await SharedPreferences.getInstance();
  final saved = preferences.getString('cashier_fixture_session');
  final savedActor = saved == null
      ? null
      : (jsonDecode(saved) as Map)['user']['id'];
  if (savedActor == const String.fromEnvironment('FIXTURE_ACTOR')) {
    await client.auth.setInitialSession(saved!);
  } else {
    await client.auth.signInWithPassword(
      email: 'fixture@example.invalid',
      password: 'synthetic-test-only',
    );
    await preferences.setString(
      'cashier_fixture_session',
      jsonEncode(client.auth.currentSession!.toJson()),
    );
  }
  debugPrint('Fixture stage: local storage');
  final di = GetIt.instance;
  di.registerSingleton<SupabaseClient>(client);
  await initOfflineCashierDI(di);
  debugPrint('Fixture stage: application');
  final cubit = di<OfflineWorkspaceCubit>();
  final user = client.auth.currentUser;
  if (user == null) throw StateError('Synthetic login missing');
  final login = FixtureLogin(
    UserEntity(
      id: user.id,
      loungeId: user.appMetadata['lounge_id'] as String,
      email: 'fixture@example.invalid',
      name: 'Fixture',
      role: UserRole.cashier,
    ),
  );
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: const Locale('ar'),
      saveLocale: false,
      path: 'assets/translations',
      child: ScreenUtilInit(
        designSize: const Size(1440, 900),
        builder: (context, _) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.scaffoldBackground,
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Tajawal'),
          ),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<LoginCubit>.value(value: login),
              BlocProvider<OfflineWorkspaceCubit>.value(value: cubit),
            ],
            child: const OfflineWorkspacePage(),
          ),
        ),
      ),
    ),
  );
}
