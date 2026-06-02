import 'package:go_router/go_router.dart';
import 'router_keys.dart';
import '../../features/auth/presentation/login/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/di.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/auth/domain/entities/admin_entity.dart';

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
          // In a real app, you'd get the admin from a Cubit/Provider
          // For now, we'll default to loungeAdmin or get it from state if available
          return const DashboardScreen(role: AdminRole.loungeAdmin);
        },
      ),
      GoRoute(
        path: RouterKeys.superAdminDashboard,
        builder: (context, state) => const DashboardScreen(role: AdminRole.superAdmin),
      ),
      GoRoute(
        path: RouterKeys.loungeAdminDashboard,
        builder: (context, state) => const DashboardScreen(role: AdminRole.loungeAdmin),
      ),
    ],
  );
}
