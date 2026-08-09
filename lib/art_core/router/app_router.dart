import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/auth/presentation/login/login_state.dart';
import '../../features/auth/domain/entities/admin_entity.dart';
import '../../features/auth/presentation/login/login_screen.dart';
import '../../features/super_admin/analytics/presentation/dashboard_screen.dart' as super_dashboard;
import '../../features/super_admin/lounge_management/presentation/pages/lounges_page.dart' as super_lounges;
import '../../features/lounge_admin/live_operations/presentation/pages/bookings_page.dart' as lounge_live;
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

        // If not authenticated, force login
        if (authState.status != LoginStatus.authenticated && 
            authState.status != LoginStatus.success) {
          return isLoggingIn ? null : RouterKeys.login;
        }

        // If authenticated, prevent going back to login
        if (isLoggingIn) {
          if (authState.admin?.role == AdminRole.superAdmin) {
            return RouterKeys.superAdminDashboard;
          } else {
            return RouterKeys.loungeAdminLiveOps;
          }
        }

        // Root redirection based on role
        if (state.matchedLocation == RouterKeys.root) {
          if (authState.admin?.role == AdminRole.superAdmin) {
            return RouterKeys.superAdminDashboard;
          } else {
            return RouterKeys.loungeAdminLiveOps;
          }
        }

        // Role-based route guards
        final bool isSuperAdminRoute = state.matchedLocation.startsWith('/super-admin');
        final bool isLoungeAdminRoute = state.matchedLocation.startsWith('/lounge-admin');

        if (isSuperAdminRoute && authState.admin?.role != AdminRole.superAdmin) {
          return RouterKeys.loungeAdminLiveOps;
        }

        if (isLoungeAdminRoute && authState.admin?.role != AdminRole.loungeAdmin) {
          return RouterKeys.superAdminDashboard;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouterKeys.login,
          builder: (context, state) => const LoginScreen(),
        ),
        // Super Admin Routes
        GoRoute(
          path: RouterKeys.superAdminDashboard,
          builder: (context, state) => const super_dashboard.DashboardScreen(role: AdminRole.superAdmin),
        ),
        GoRoute(
          path: RouterKeys.superAdminLounges,
          builder: (context, state) => const super_lounges.LoungesPage(),
        ),
        // Lounge Admin Routes
        GoRoute(
          path: RouterKeys.loungeAdminLiveOps,
          builder: (context, state) => const lounge_live.BookingsPage(),
        ),
      ],
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
