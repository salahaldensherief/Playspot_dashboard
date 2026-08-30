import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    final loginCubit = sl<LoginCubit>();
    loginCubit.checkInitialAuth();
    _appRouter = AppRouter(loginCubit);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final Size designSize;
        if (width < 600) {
          designSize = const Size(375, 812); // Mobile
        } else if (width < 1100) {
          designSize = const Size(1024, 1366); // Tablet
        } else {
          designSize = const Size(1440, 1024); // Desktop
        }

        return ScreenUtilInit(
          key: ValueKey(designSize.width), // Force full tree rebuild on breakpoint hit
          designSize: designSize,
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
                textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
              ),
              routerConfig: _appRouter.router,
            );
          },
        );
      },
    );
  }
}
