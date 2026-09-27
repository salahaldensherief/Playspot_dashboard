import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/permissions/presentation/cubit/permissions_cubit.dart';

extension PermissionExtension on BuildContext {
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

  /// UI permission evaluation mirrors the canonical server permission matrix.
  ///
  /// This is a presentation guard only; backend RPC/RLS authorization remains
  /// authoritative for every sensitive read or mutation.
  bool hasPermission(String key) {
    final user = read<LoginCubit>().state.user;
    if (user == null || key.trim().isEmpty) return false;

    // Platform administrators intentionally operate outside lounge-scoped RBAC.
    if (user.isSuperAdmin) return true;

    return read<PermissionsCubit>().hasPermission(
      key,
      userRole: _permissionRole(user),
      userId: user.id,
    );
  }
}
