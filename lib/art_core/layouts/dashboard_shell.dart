import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/auth/presentation/login/login_state.dart';
import '../widgets/geolocation_handler.dart';
import 'shell/dashboard_shell_content.dart';
import 'shell/shell_route_resolver.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  final String location;

  const DashboardShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) => prev.user != curr.user,
      builder: (context, loginState) {
        final user = loginState.user;
        final isSuperAdmin = user?.role == UserRole.superAdmin;

        final routeInfo = ShellRouteResolver.resolve(
          location: location,
          isSuperAdmin: isSuperAdmin,
        );

        return GeolocationHandler(
          child: DashboardShellContent(
            location: location,
            activeRoute: routeInfo.activeRoute,
            title: routeInfo.title,
            user: user,
            isSuperAdmin: isSuperAdmin,
            child: child,
          ),
        );
      },
    );
  }
}
