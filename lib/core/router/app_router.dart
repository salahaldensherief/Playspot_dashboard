import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_screen.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_screen.dart' as dashboard;
import 'package:play_spot_dashboard/features/lounges/presentation/pages/lounges_page.dart' as lounges;
import 'package:play_spot_dashboard/features/users/presentation/pages/users_page.dart' as users;
import 'package:play_spot_dashboard/features/categories/presentation/pages/categories_page.dart' as categories;
import 'package:play_spot_dashboard/features/marketing/presentation/pages/marketing_page.dart' as marketing;
import 'package:play_spot_dashboard/features/payouts/presentation/pages/super_admin_payouts_page.dart' as payouts;
import 'package:play_spot_dashboard/features/payouts/presentation/pages/lounge_admin_payouts_page.dart' as lounge_payouts;
import 'package:play_spot_dashboard/features/bookings/presentation/pages/bookings_page.dart' as bookings;
import 'package:play_spot_dashboard/features/rooms/presentation/pages/room_management_page.dart' as rooms;
import 'package:play_spot_dashboard/features/onboarding/presentation/pages/lounge_setup_page.dart' as onboarding;
import 'package:play_spot_dashboard/features/lounges/presentation/pages/extras_management_page.dart' as extras;
import 'package:play_spot_dashboard/features/lounges/presentation/pages/lounge_profile_page.dart' as lounge_profile;
import 'package:play_spot_dashboard/features/auth/presentation/profile/profile_page.dart' as profile;
import 'package:play_spot_dashboard/art_core/layouts/dashboard_shell.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/users/presentation/cubit/admin_management_cubit.dart';
import 'package:play_spot_dashboard/features/categories/presentation/cubit/category_cubit.dart';
import 'package:play_spot_dashboard/features/marketing/presentation/cubit/marketing_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/extras_cubit.dart';
import '../../features/bookings/presentation/cubit/booking_cubit.dart';
import '../di/di.dart';
import 'router_keys.dart';

class AppRouter {
  final LoginCubit authCubit;

  AppRouter(this.authCubit);

  late final router = GoRouter(
    initialLocation: RouterKeys.root,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
        final authState = authCubit.state;
        final bool isLoggingIn = state.matchedLocation == RouterKeys.login;
        final user = authState.user;

        // 1. Auth Guard
        if (authState.status != LoginStatus.authenticated && 
            authState.status != LoginStatus.success) {
          return isLoggingIn ? null : RouterKeys.login;
        }

        // 2. Wait for user data
        if (user == null) return isLoggingIn ? null : null;

        final bool isLoungeAdmin = user.role == UserRole.loungeAdmin;
        final bool isSuperAdmin = user.role == UserRole.superAdmin;
        final bool isOnboardingPath = state.matchedLocation == RouterKeys.loungeOnboarding;

        // 3. Forced Onboarding Logic
        if (isLoungeAdmin && !user.isSetupCompleted) {
          if (!isOnboardingPath) {
            return RouterKeys.loungeOnboarding;
          }
          return null;
        }

        // 4. Prevent onboarding if already completed
        if (isOnboardingPath && user.isSetupCompleted) {
          return RouterKeys.loungeAdminLiveOps;
        }

        // 5. Handle redirections from Login or Root
        if (isLoggingIn || state.matchedLocation == RouterKeys.root) {
          if (isSuperAdmin) return RouterKeys.superAdminDashboard;
          if (isLoungeAdmin) return RouterKeys.loungeAdminLiveOps;
        }

        // 6. Protect Super Admin Routes
        final bool isSuperAdminRoute = state.matchedLocation.startsWith('/super-admin');
        if (isSuperAdminRoute && !isSuperAdmin) {
          return RouterKeys.loungeAdminLiveOps;
        }

        return null;
      },
      routes: [
        ShellRoute(
          builder: (context, state, child) => BlocProvider(
            create: (context) => sl<LoginCubit>()..checkInitialAuth(),
            child: child,
          ),
          routes: [
            GoRoute(
              path: RouterKeys.login,
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              path: RouterKeys.loungeOnboarding,
              builder: (context, state) => BlocProvider(
                create: (context) => sl<OnboardingCubit>(),
                child: BlocProvider(
                  create: (context) => sl<CategoryCubit>()..loadCategories(),
                  child: const onboarding.LoungeSetupPage(),
                ),
              ),
            ),
            
            ShellRoute(
              builder: (context, state, child) {
                return DashboardShell(
                  location: state.matchedLocation,
                  child: child,
                );
              },
              routes: [
                GoRoute(
                  path: RouterKeys.superAdminDashboard,
                  builder: (context, state) => BlocProvider(
                    create: (context) => sl<BookingCubit>()..startWatchingBookings(),
                    child: BlocProvider(
                      create: (context) => sl<DashboardCubit>()..loadDashboardData(),
                      child: const dashboard.DashboardScreen(role: UserRole.superAdmin),
                    ),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminLounges,
                  builder: (context, state) => BlocProvider(
                    create: (context) => sl<LoungeCubit>()..fetchLounges(),
                    child: const lounges.LoungesPage(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminUsers,
                  builder: (context, state) => BlocProvider(
                    create: (context) => sl<AdminManagementCubit>()..fetchAdmins(),
                    child: const users.UsersPage(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminCategories,
                  builder: (context, state) => BlocProvider(
                    create: (context) => sl<CategoryCubit>()..loadCategories(),
                    child: const categories.CategoriesPage(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminMarketing,
                  builder: (context, state) => BlocProvider(
                    create: (context) => sl<MarketingCubit>()..loadPromotions(),
                    child: const marketing.MarketingPage(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.superAdminPayouts,
                  builder: (context, state) => const payouts.SuperAdminPayoutsPage(),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminLiveOps,
                  builder: (context, state) => BlocProvider(
                    create: (context) => sl<BookingCubit>()..startWatchingBookings(loungeId: context.read<LoginCubit>().state.user?.loungeId),
                    child: const bookings.BookingsPage(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminRooms,
                  builder: (context, state) => BlocProvider(
                    create: (context) => sl<RoomCubit>()..watchRooms(context.read<LoginCubit>().state.user?.loungeId ?? ''),
                    child: BlocProvider(
                      create: (context) => sl<CategoryCubit>()..loadCategories(),
                      child: const rooms.RoomManagementPage(),
                    ),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminExtras,
                  builder: (context, state) => BlocProvider(
                    create: (context) => sl<ExtrasCubit>()..loadExtras(context.read<LoginCubit>().state.user?.loungeId ?? ''),
                    child: const extras.ExtrasManagementPage(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminMarketing,
                  builder: (context, state) => BlocProvider(
                    create: (context) => sl<MarketingCubit>()..loadPromotions(loungeId: context.read<LoginCubit>().state.user?.loungeId),
                    child: const marketing.MarketingPage(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminPayouts,
                  builder: (context, state) => const lounge_payouts.LoungeAdminPayoutsPage(),
                ),
                GoRoute(
                  path: RouterKeys.loungeAdminProfile,
                  builder: (context, state) => BlocProvider(
                    create: (context) => sl<LoungeCubit>(),
                    child: const lounge_profile.LoungeProfilePage(),
                  ),
                ),
                GoRoute(
                  path: RouterKeys.profile,
                  builder: (context, state) => const profile.ProfilePage(),
                ),
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
              Text(AppStrings.pageNotFound, style: const TextStyle(color: Colors.white, fontSize: 24)),
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

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) {
            if (WidgetsBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (hasListeners) {
                  notifyListeners();
                }
              });
            }
          },
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
