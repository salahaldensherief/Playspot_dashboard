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
import 'package:play_spot_dashboard/features/bookings/presentation/pages/bookings_page.dart' as bookings;
import 'package:play_spot_dashboard/features/rooms/presentation/pages/room_management_page.dart' as rooms;
import 'package:play_spot_dashboard/features/onboarding/presentation/pages/lounge_setup_page.dart' as onboarding;
import 'package:play_spot_dashboard/features/lounges/presentation/pages/extras_management_page.dart' as extras;
import 'package:play_spot_dashboard/features/lounges/presentation/pages/lounge_profile_page.dart' as lounge_profile;
import 'package:play_spot_dashboard/features/marketing/presentation/pages/marketing_page.dart' as marketing;
import 'package:play_spot_dashboard/features/auth/presentation/profile/profile_page.dart' as profile;
import 'package:play_spot_dashboard/art_core/layouts/dashboard_shell.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
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

        debugPrint('--- ROUTER DEBUG ---');
        debugPrint('Path: ${state.matchedLocation}');
        debugPrint('Role: ${user.role}');
        debugPrint('LoungeID: "${user.loungeId}"');
        debugPrint('Setup Completed: ${user.isSetupCompleted}');

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

        // 4. Handle redirections from Login or Root
        if (isLoggingIn || state.matchedLocation == RouterKeys.root) {
          if (isSuperAdmin) return RouterKeys.superAdminDashboard;
          if (isLoungeAdmin) return RouterKeys.loungeAdminLiveOps;
        }

        // 5. Protect Super Admin Routes
        final bool isSuperAdminRoute = state.matchedLocation.startsWith('/super-admin');
        if (isSuperAdminRoute && !isSuperAdmin) {
          return RouterKeys.loungeAdminLiveOps;
        }

        // 6. Prevent onboarding if already completed
        if (isOnboardingPath && user.isSetupCompleted) {
          return RouterKeys.loungeAdminLiveOps;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouterKeys.login,
          pageBuilder: (context, state) => const NoTransitionPage(child: LoginScreen()),
        ),
        GoRoute(
          path: RouterKeys.loungeOnboarding,
          pageBuilder: (context, state) => const NoTransitionPage(child: onboarding.LoungeSetupPage()),
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
              pageBuilder: (context, state) => NoTransitionPage(
                child: dashboard.DashboardScreen(role: UserRole.superAdmin),
              ),
            ),
            GoRoute(
              path: RouterKeys.superAdminLounges,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: lounges.LoungesPage(),
              ),
            ),
            GoRoute(
              path: RouterKeys.superAdminUsers,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: users.UsersPage(),
              ),
            ),
            GoRoute(
              path: RouterKeys.superAdminCategories,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: categories.CategoriesPage(),
              ),
            ),
            GoRoute(
              path: RouterKeys.superAdminMarketing,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: marketing.MarketingPage(),
              ),
            ),
            GoRoute(
              path: RouterKeys.loungeAdminLiveOps,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: bookings.BookingsPage(),
              ),
            ),
            GoRoute(
              path: RouterKeys.loungeAdminRooms,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: rooms.RoomManagementPage(),
              ),
            ),
            GoRoute(
              path: RouterKeys.loungeAdminExtras,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: extras.ExtrasManagementPage(),
              ),
            ),
            GoRoute(
              path: RouterKeys.loungeAdminMarketing,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: marketing.MarketingPage(),
              ),
            ),
            GoRoute(
              path: RouterKeys.loungeAdminProfile,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: lounge_profile.LoungeProfilePage(),
              ),
            ),
            GoRoute(
              path: RouterKeys.profile,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: profile.ProfilePage(),
              ),
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
            // Using PostFrameCallback is the most stable way to handle navigation
            // triggers in Flutter Web to avoid "debugDuringDeviceUpdate" errors.
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
