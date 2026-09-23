import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:js_interop';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/di/provider_scope.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_shell.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/router/go_router_refresh_stream.dart';
import 'package:play_spot_dashboard/core/router/lounge_admin_routes.dart';
import 'package:play_spot_dashboard/core/router/router_guards.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/core/router/super_admin_routes.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/lounge_stats_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_screen.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/categories/presentation/categories/category_cubit.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_cubit.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/pages/kyc_pending_page.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/extras_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/pages/lounge_setup_page.dart'
    as onboarding;
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/reviews/presentation/reviews_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';

@JS('removeSplash')
external void _removeWebSplash();

void _hideWebSplash() {
  if (kIsWeb) {
    try {
      _removeWebSplash();
    } catch (_) {}
  }
}

class AppRouter {
  final LoginCubit authCubit;

  AppRouter(this.authCubit);

  late final router = GoRouter(
    initialLocation: RouterKeys.root,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) =>
        RouterGuards.redirect(context, state, authCubit),
    routes: [
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return BlocProvider<LoginCubit>.value(
            value: authCubit,
            child: BlocBuilder<LoginCubit, LoginState>(
              buildWhen: (previous, current) =>
                  previous.status != current.status,
              builder: (context, authState) {
                if (authState.status == LoginStatus.checking) {
                  return const Scaffold(
                    backgroundColor: AppColors.scaffoldBackground,
                  );
                }
                _hideWebSplash();
                return child;
              },
            ),
          );
        },
        routes: [
          GoRoute(
            path: RouterKeys.login,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LoginScreen()),
          ),
          GoRoute(
            path: RouterKeys.loungeOnboarding,
            pageBuilder: (context, state) => NoTransitionPage(
              child: MultiBlocProviderScope(
                providers: [
                  BlocProvider(create: (_) => sl<OnboardingCubit>()),
                  BlocProvider(create: (_) => sl<CategoryCubit>()),
                  BlocProvider(create: (_) => sl<KycCubit>()),
                ],
                child: const onboarding.LoungeSetupPage(),
              ),
            ),
          ),
          GoRoute(
            path: RouterKeys.kycPending,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: KycPendingPage()),
          ),

          // Core dashboard shell with hoisted persistent Cubits
          ShellRoute(
            builder: (BuildContext context, GoRouterState state, Widget child) {
              return MultiBlocProviderScope(
                providers: [
                  BlocProvider<ShiftCubit>(create: (_) => sl<ShiftCubit>()),
                  BlocProvider<BookingCubit>(create: (_) => sl<BookingCubit>()),
                  BlocProvider<LoungeCubit>(create: (_) => sl<LoungeCubit>()),
                  BlocProvider<RoomCubit>(create: (_) => sl<RoomCubit>()),
                  BlocProvider<LoungeStatsCubit>(
                    create: (_) => sl<LoungeStatsCubit>(),
                  ),
                  BlocProvider<DashboardCubit>(
                    create: (_) => sl<DashboardCubit>(),
                  ),
                  BlocProvider<ExtrasCubit>(create: (_) => sl<ExtrasCubit>()),
                  BlocProvider<ReviewsCubit>(create: (_) => sl<ReviewsCubit>()),
                  BlocProvider<ClientRequestsCubit>.value(
                    value: sl<ClientRequestsCubit>(),
                  ),
                  BlocProvider<PermissionsCubit>.value(
                    value: sl<PermissionsCubit>(),
                  ),
                ],
                child: DashboardShell(
                  location: state.matchedLocation,
                  child: child,
                ),
              );
            },
            routes: [
              ...getSuperAdminRoutes(),
              ...getLoungeAdminRoutes(authCubit),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.pageNotFound,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 16),
            AppButton(
              onPressed: () => context.go(RouterKeys.root),
              text: AppStrings.goHome,
            ),
          ],
        ),
      ),
    ),
  );
}
