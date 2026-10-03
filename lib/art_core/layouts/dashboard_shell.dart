import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/auth/presentation/login/login_state.dart';
import '../../features/permissions/presentation/cubit/permissions_cubit.dart';
import '../widgets/geolocation_handler.dart';
import 'shell/dashboard_shell_content.dart';
import 'shell/shell_route_resolver.dart';

class DashboardShell extends StatefulWidget {
  final Widget child;
  final String location;

  const DashboardShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  String? _loadedPermissionIdentity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncPermissions(context.read<LoginCubit>().state.user);
    });
  }

  String _permissionRole(UserEntity user) {
    final rawRole = user.rawRole?.trim();
    if (rawRole != null && rawRole.isNotEmpty) return rawRole;

    return switch (user.role) {
      UserRole.superAdmin => 'super_admin',
      UserRole.owner => 'owner',
      UserRole.manager => 'manager',
      UserRole.cashier => 'cashier',
      UserRole.staff => 'staff',
      UserRole.user => 'user',
    };
  }

  Future<void> _syncPermissions(UserEntity? user) async {
    if (!mounted) return;

    final permissionsCubit = context.read<PermissionsCubit>();
    if (user == null) {
      _loadedPermissionIdentity = null;
      permissionsCubit.setActiveLoungeId(null);
      return;
    }

    final loungeId = user.loungeId?.trim();
    final identity = '${user.id}|${_permissionRole(user)}|${loungeId ?? ''}';
    if (_loadedPermissionIdentity == identity) return;
    _loadedPermissionIdentity = identity;

    await permissionsCubit.loadUserPermissions(
      _permissionRole(user),
      loungeId: loungeId,
      userId: user.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // Rebuild localized labels when the locale changes.
    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (previous, current) => previous.user != current.user,
      listener: (context, state) {
        _syncPermissions(state.user);
      },
      child: BlocBuilder<LoginCubit, LoginState>(
        buildWhen: (prev, curr) => prev.user != curr.user,
        builder: (context, loginState) {
          final user = loginState.user;
          final isSuperAdmin = user?.role == UserRole.superAdmin;

          final routeInfo = ShellRouteResolver.resolve(
            location: widget.location,
            isSuperAdmin: isSuperAdmin,
          );

          return GeolocationHandler(
            child: DashboardShellContent(
              location: widget.location,
              activeRoute: routeInfo.activeRoute,
              title: routeInfo.title,
              user: user,
              isSuperAdmin: isSuperAdmin,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
