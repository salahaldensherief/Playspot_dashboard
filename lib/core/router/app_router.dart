import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/features/auth/presetation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presetation/login/login_state.dart';
import '../../features/auth/presetation/login/login_screen.dart';
import 'router_keys.dart';
import '../../features/dashboard/presentation/screens/super_admin_dashboard.dart';
import '../../features/dashboard/presentation/screens/lounge_admin_dashboard.dart';
import '../../features/auth/domain/entities/admin_entity.dart';

class AppRouter {
  final LoginCubit authCubit;

  AppRouter(this.authCubit);

  late final router = GoRouter(
    initialLocation: RouterKeys.dashboard,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final bool loggingIn = state.matchedLocation == RouterKeys.login;

      if (authState.status == LoginStatus.loading) {
        return null;
      }

      if (authState.status != LoginStatus.authenticated) {
        return loggingIn ? null : RouterKeys.login;
      }

      if (loggingIn) {
        return RouterKeys.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouterKeys.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouterKeys.dashboard,
        builder: (context, state) {
          final admin = authCubit.state.admin;
          if (admin?.role == AdminRole.superAdmin) {
            return const SuperAdminDashboard();
          } else {
            return const LoungeAdminDashboard();
          }
        },
      ),
      GoRoute(
        path: RouterKeys.superAdminDashboard,
        builder: (context, state) => const SuperAdminDashboard(),
      ),
      GoRoute(
        path: RouterKeys.loungeAdminDashboard,
        builder: (context, state) => const LoungeAdminDashboard(),
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

