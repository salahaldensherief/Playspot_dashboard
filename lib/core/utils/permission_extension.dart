import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/permissions/presentation/cubit/permissions_cubit.dart';

extension PermissionExtension on BuildContext {
  /// Core dynamic permission evaluator based on PermissionsCubit state & cache
  bool hasPermission(String key) {
    UserEntity? user;
    try {
      user = read<LoginCubit>().state.user;
    } catch (_) {
      if (GetIt.I.isRegistered<LoginCubit>()) {
        user = GetIt.I<LoginCubit>().state.user;
      }
    }

    if (user == null) return false;

    // Level 0 Bypass: Platform Admin (Super Admin) & Lounge Owner have full access
    if (user.isSuperAdmin || user.isOwner) {
      return true;
    }

    final roleStr = user.rawRole ?? user.role.name;
    try {
      return read<PermissionsCubit>().hasPermission(key, userRole: roleStr);
    } catch (_) {
      if (GetIt.I.isRegistered<PermissionsCubit>()) {
        return GetIt.I<PermissionsCubit>().hasPermission(key, userRole: roleStr);
      }
    }
    return false;
  }
}
