import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/permission_key.dart';
import '../../domain/use_cases/get_role_permissions_use_case.dart';
import '../../domain/use_cases/get_user_permissions_use_case.dart';
import '../../domain/use_cases/update_role_permission_use_case.dart';
import 'permissions_state.dart';

class PermissionsCubit extends Cubit<PermissionsState> {
  final GetRolePermissionsUseCase getRolePermissionsUseCase;
  final GetUserPermissionsUseCase getUserPermissionsUseCase;
  final UpdateRolePermissionUseCase updateRolePermissionUseCase;
  String? _activeLoungeId;
  String? _editorLoungeId;
  int _userRequest = 0;
  int _editorRequest = 0;
  bool _saving = false;

  PermissionsCubit({
    required this.getRolePermissionsUseCase,
    required this.getUserPermissionsUseCase,
    required this.updateRolePermissionUseCase,
  }) : super(PermissionsState.initial());

  void setActiveLoungeId(String? loungeId) {
    final next = loungeId?.trim();
    if (next == _activeLoungeId) return;
    _activeLoungeId = next;
    _userRequest++;
    if (!isClosed) emit(state.copyWith(userPermissions: const {}));
  }

  Future<void> loadUserPermissions(String role, {String? loungeId, String? userId}) async {
    if (isClosed) return;
    final request = ++_userRequest;
    _activeLoungeId = loungeId?.trim();
    emit(state.copyWith(userRole: _normalizeRole(role), userId: userId,
      userPermissions: const {}));
    final result = await getUserPermissionsUseCase(loungeId: _activeLoungeId);
    if (isClosed || request != _userRequest) return;
    result.fold(
      (failure) => emit(state.copyWith(userPermissions: const {},
        status: PermissionsStatus.failure, errorMessage: failure.message)),
      (permissions) => emit(state.copyWith(
        userPermissions: {for (final p in permissions) p.key: p.isEnabled},
        status: PermissionsStatus.success)),
    );
  }

  Future<void> fetchPermissions(String role, {String? loungeId}) async {
    if (isClosed) return;
    final request = ++_editorRequest;
    final cleanRole = _normalizeRole(role);
    _editorLoungeId = loungeId?.trim();
    emit(state.copyWith(status: PermissionsStatus.loading,
      selectedRole: cleanRole, permissions: const []));
    final result = await getRolePermissionsUseCase(cleanRole, loungeId: _editorLoungeId);
    if (isClosed || request != _editorRequest) return;
    result.fold(
      (failure) => emit(state.copyWith(status: PermissionsStatus.failure,
        errorMessage: failure.message)),
      (permissions) => emit(state.copyWith(status: PermissionsStatus.success,
        permissions: permissions)),
    );
  }

  Future<void> fetchLoungeRolePermissionsPage({
    required String loungeId, int page = 1, int pageSize = 50,
  }) async {
    if (isClosed || loungeId.trim().isEmpty) return;
    final request = ++_editorRequest;
    _editorLoungeId = loungeId.trim();
    emit(state.copyWith(status: PermissionsStatus.loading));
    final result = await getRolePermissionsUseCase.repository.getLoungeRolePermissionsPage(
      loungeId: _editorLoungeId ?? '', page: page, pageSize: pageSize);
    if (isClosed || request != _editorRequest) return;
    result.fold(
      (failure) => emit(state.copyWith(status: PermissionsStatus.failure,
        errorMessage: failure.message)),
      (result) => emit(state.copyWith(status: PermissionsStatus.success,
        permissions: result.items, page: result.page,
        pageSize: result.pageSize, totalCount: result.totalCount)),
    );
  }

  Future<void> togglePermission(String role, String key, bool value, {String? loungeId}) async {
    if (isClosed || key.isEmpty || _saving) return;
    _saving = true;
    final targetLounge = loungeId?.trim() ?? _editorLoungeId;
    final cleanRole = _normalizeRole(role);
    final request = _editorRequest;
    final result = await updateRolePermissionUseCase(cleanRole, key, value,
      loungeId: targetLounge);
    _saving = false;
    if (isClosed || request != _editorRequest) return;
    await result.fold(
      (failure) async => emit(state.copyWith(status: PermissionsStatus.failure,
        errorMessage: failure.message)),
      (_) async {
        await fetchPermissions(cleanRole, loungeId: targetLounge);
        final activeRole = state.userRole;
        if (activeRole != null && targetLounge == _activeLoungeId) {
          await loadUserPermissions(activeRole, loungeId: _activeLoungeId,
            userId: state.userId);
        }
      },
    );
  }

  String _normalizeRole(String role) {
    switch (role.toLowerCase().trim()) {
      case 'superadmin': case 'super_admin': return 'super_admin';
      case 'lounge_owner': case 'owner': return 'owner';
      case 'lounge_admin': case 'admin': case 'manager': return 'manager';
      case 'cashier': return 'cashier';
      case 'staff': return 'staff';
      default: return '';
    }
  }

  bool hasPermission(String key, {String? userRole, String? userId}) {
    final role = _normalizeRole(userRole ?? state.userRole ?? '');
    if (key.isEmpty || role.isEmpty || role != state.userRole) return false;
    if (userId == null || userId != state.userId) return false;
    return state.userPermissions[PermissionKey.canonical(key)] == true;
  }
}
