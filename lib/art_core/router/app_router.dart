import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'router_keys.dart';
import '../../features/auth/presetation/login/login_screen.dart';
import '../../features/dashboard/presetation/super_admin/super_admin_dashboard_screen.dart';
import '../../features/dashboard/presetation/lounge_admin/lounge_admin_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di.dart';
import '../../features/auth/presetation/login/login_cubit.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: RouterKeys.root,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final bool loggingIn = state.matchedLocation == RouterKeys.login;

      if (session == null) {
        return loggingIn ? null : RouterKeys.login;
      }

      if (loggingIn) {
        return RouterKeys.root;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouterKeys.login,
        builder: (context, state) => BlocProvider(
          create: (context) => sl<LoginCubit>(),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: RouterKeys.root,
        builder: (context, state) {
          // This should ideally check user role from a cubit or similar
          // For now, redirecting to login if no session, else we'd need more logic.
          return const Center(child: CircularProgressIndicator());
        },
      ),
      GoRoute(
        path: RouterKeys.superAdminDashboard,
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
      GoRoute(
        path: RouterKeys.loungeAdminDashboard,
        builder: (context, state) => const LoungeAdminDashboardScreen(),
      ),
    ],
  );
}
