import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'art_core/theme/app_colors.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/login/login_cubit.dart';
import 'core/di/di.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final LoginCubit _loginCubit;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _loginCubit = sl<LoginCubit>()..checkInitialAuth();
    _appRouter = AppRouter(_loginCubit);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _loginCubit,
      child: ScreenUtilInit(
        designSize: const Size(1440, 1024),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'PlaySpot Dashboard',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: ThemeData(
              scaffoldBackgroundColor: AppColors.scaffoldBackground,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.neonBlue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              fontFamily: 'Orbitron',
            ),
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
