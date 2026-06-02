import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import '../../features/auth/presentation/login/login_screen.dart';
import 'router_keys.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
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
          return DashboardScreen(role: admin?.role ?? AdminRole.loungeAdmin);
        },
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
