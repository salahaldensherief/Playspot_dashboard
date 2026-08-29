import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/permissions/domain/entities/permission_item_entity.dart';
import '../../domain/use_cases/get_role_permissions_use_case.dart';
import '../../domain/use_cases/update_role_permission_use_case.dart';
import 'permissions_state.dart';

class PermissionsCubit extends Cubit<PermissionsState> {
  final GetRolePermissionsUseCase getRolePermissionsUseCase;
  final UpdateRolePermissionUseCase updateRolePermissionUseCase;

  PermissionsCubit({
    required this.getRolePermissionsUseCase,
    required this.updateRolePermissionUseCase,
  }) : super(PermissionsState.initial());

  Future<void> fetchPermissions(String role) async {
    emit(state.copyWith(status: PermissionsStatus.loading, selectedRole: role));
    final result = await getRolePermissionsUseCase(role);
    
    result.fold(
      (failure) => emit(state.copyWith(status: PermissionsStatus.failure, errorMessage: failure.message)),
      (permissions) => emit(state.copyWith(status: PermissionsStatus.success, permissions: permissions)),
    );
  }

  Future<void> togglePermission(String role, String key, bool value) async {
    // Optimistic update
    final oldPermissions = List<PermissionItemEntity>.from(state.permissions);
    final updatedPermissions = state.permissions.map((p) {
      if (p.key == key) return p.copyWith(isEnabled: value);
      return p;
    }).toList();

    emit(state.copyWith(permissions: updatedPermissions));

    final result = await updateRolePermissionUseCase(role, key, value);
    
    result.fold(
      (failure) {
        // Rollback on failure
        emit(state.copyWith(permissions: oldPermissions, status: PermissionsStatus.failure, errorMessage: failure.message));
      },
      (_) => null, // Success, already updated optimistically
    );
  }

  bool hasPermission(String key) {
    try {
      return state.permissions.firstWhere((p) => p.key == key).isEnabled;
    } catch (_) {
      return false;
    }
  }
}
