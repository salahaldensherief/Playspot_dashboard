import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/admin_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_screen.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_screen.dart' as dashboard;
import 'package:play_spot_dashboard/features/lounges/presentation/pages/lounges_page.dart' as lounges;
import 'package:play_spot_dashboard/features/users/presentation/pages/users_page.dart' as users;
import 'package:play_spot_dashboard/features/bookings/presentation/pages/bookings_page.dart' as bookings;
import 'package:play_spot_dashboard/features/rooms/presentation/pages/room_management_page.dart' as rooms;
import 'package:play_spot_dashboard/features/onboarding/presentation/pages/lounge_setup_page.dart' as onboarding;
import 'package:play_spot_dashboard/art_core/layouts/dashboard_shell.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'router_keys.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final authCubit = context.read<LoginCubit>();

    return GoRouter(
      initialLocation: RouterKeys.root,
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final authState = authCubit.state;
        final bool isLoggingIn = state.matchedLocation == RouterKeys.login;
        final admin = authState.admin;

        // 1. Auth Guard
        if (authState.status != LoginStatus.authenticated && 
            authState.status != LoginStatus.success) {
          return isLoggingIn ? null : RouterKeys.login;
        }

        // 2. Wait for admin data
        if (admin == null) return isLoggingIn ? null : null;

        debugPrint('--- ROUTER DEBUG ---');
        debugPrint('Path: ${state.matchedLocation}');
        debugPrint('Role: ${admin.role}');
        debugPrint('LoungeID: "${admin.loungeId}"');

        final bool isLoungeAdmin = admin.role == AdminRole.loungeAdmin;
        final bool hasNoLounge = admin.loungeId == null || admin.loungeId!.trim().isEmpty;
        final bool isOnboardingPath = state.matchedLocation == RouterKeys.loungeOnboarding;

        // 3. Forced Onboarding Logic
        if (isLoungeAdmin && hasNoLounge) {
          if (!isOnboardingPath) {
            debugPrint('FORCING ONBOARDING');
            return RouterKeys.loungeOnboarding;
          }
          return null;
        }

        // 4. Handle redirections from Login or Root
        if (isLoggingIn || state.matchedLocation == RouterKeys.root) {
          if (admin.role == AdminRole.superAdmin) return RouterKeys.superAdminDashboard;
          if (isLoungeAdmin) return RouterKeys.loungeAdminLiveOps;
        }

        // 5. Protect Super Admin Routes
        final bool isSuperAdminRoute = state.matchedLocation.startsWith('/super-admin');
        if (isSuperAdminRoute && admin.role != AdminRole.superAdmin) {
          return RouterKeys.loungeAdminLiveOps;
        }

        // 6. Prevent onboarding if already has a lounge
        if (isOnboardingPath && !hasNoLounge) {
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
                child: dashboard.DashboardScreen(role: AdminRole.superAdmin),
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
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
