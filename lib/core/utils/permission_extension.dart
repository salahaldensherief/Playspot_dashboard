import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/permissions/presentation/cubit/permissions_cubit.dart';

extension PermissionExtension on BuildContext {
  /// Core dynamic permission evaluator based on PermissionsCubit state & cache
  bool hasPermission(String key) {
    final user = read<LoginCubit>().state.user;
    if (user == null) return false;

    // Level 0 Bypass: Platform Admin (Super Admin) & Lounge Owner have full access
    if (user.isSuperAdmin || user.isOwner) {
      return true;
    }

    final roleStr = user.rawRole ?? user.role.name;
    return read<PermissionsCubit>().hasPermission(key, userRole: roleStr);
  }
}
