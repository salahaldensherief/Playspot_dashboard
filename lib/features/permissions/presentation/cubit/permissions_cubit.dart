import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
import 'package:play_spot_dashboard/features/permissions/data/models/permission_item_model.dart';
import 'package:play_spot_dashboard/features/permissions/domain/entities/permission_item_entity.dart';
import '../../domain/use_cases/get_role_permissions_use_case.dart';
import '../../domain/use_cases/update_role_permission_use_case.dart';
import 'permissions_state.dart';

class PermissionsCubit extends Cubit<PermissionsState> {
  final GetRolePermissionsUseCase getRolePermissionsUseCase;
  final UpdateRolePermissionUseCase updateRolePermissionUseCase;
  final LocalCacheService? cacheService;

  PermissionsCubit({
    required this.getRolePermissionsUseCase,
    required this.updateRolePermissionUseCase,
    this.cacheService,
  }) : super(PermissionsState.initial());

  String _getCacheKey(String role) => 'permissions_cache_${role.toLowerCase().trim()}';

  /// Loads permissions for the active logged-in user and populates local state & cache
  Future<void> loadUserPermissions(String role) async {
    if (isClosed) return;
    final cleanRole = role.toLowerCase().trim();
    // ignore: avoid_print
    print('DEBUG: Loading user permissions for active role: $cleanRole');

    emit(state.copyWith(userRole: cleanRole));

    // 1. Instant Cache-First Load
    final cachedData = cacheService?.getJson(_getCacheKey(cleanRole));
    if (cachedData != null && cachedData is List && cachedData.isNotEmpty) {
      try {
        final cachedList = cachedData
            .map((e) => PermissionItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final userPermMap = {for (var p in cachedList) p.key: p.isEnabled};
        emit(state.copyWith(userPermissions: userPermMap));
        // ignore: avoid_print
        print('DEBUG: Loaded ${userPermMap.length} permissions from local cache for $cleanRole');
      } catch (e) {
        // ignore: avoid_print
        print('DEBUG: Error parsing cached permissions: $e');
      }
    }

    // 2. Fetch from Remote DB to Sync
    final result = await getRolePermissionsUseCase(cleanRole);
    if (isClosed) return;

    result.fold(
      (failure) {
        // ignore: avoid_print
        print('DEBUG: User permissions fetch failure: ${failure.message}');
      },
      (permissions) {
        final userPermMap = {for (var p in permissions) p.key: p.isEnabled};
        _saveToCache(cleanRole, permissions);
        emit(state.copyWith(
          userPermissions: userPermMap,
          status: PermissionsStatus.success,
        ));
        // ignore: avoid_print
        print('DEBUG: Synced ${permissions.length} user permissions from remote DB for $cleanRole');
      },
    );
  }

  /// Fetches permissions for a specific role to display/edit in settings tab
  Future<void> fetchPermissions(String role) async {
    if (isClosed) return;
    final cleanRole = role.toLowerCase().trim();
    // ignore: avoid_print
    print('DEBUG: Fetching permissions for role: $cleanRole');

    emit(state.copyWith(status: PermissionsStatus.loading, selectedRole: cleanRole));

    // 1. Instant Cache-First Load
    final cachedData = cacheService?.getJson(_getCacheKey(cleanRole));
    if (cachedData != null && cachedData is List && cachedData.isNotEmpty) {
      try {
        final cachedList = cachedData
            .map((e) => PermissionItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        emit(state.copyWith(permissions: cachedList));
      } catch (_) {}
    }

    // 2. Remote Fetch
    final result = await getRolePermissionsUseCase(cleanRole);
    if (isClosed) return;

    result.fold(
      (failure) {
        // ignore: avoid_print
        print('DEBUG: Fetch failure: ${failure.message}');
        emit(state.copyWith(status: PermissionsStatus.failure, errorMessage: failure.message));
      },
      (permissions) {
        // ignore: avoid_print
        print('DEBUG: Fetched ${permissions.length} permissions for $cleanRole');
        _saveToCache(cleanRole, permissions);

        Map<String, bool>? updatedUserPerms;
        if (cleanRole == (state.userRole ?? '').toLowerCase().trim()) {
          updatedUserPerms = {for (var p in permissions) p.key: p.isEnabled};
        }

        emit(state.copyWith(
          status: PermissionsStatus.success,
          permissions: permissions,
          userPermissions: updatedUserPerms ?? state.userPermissions,
        ));
      },
    );
  }

  /// Toggles a permission for a role, updates remote DB, cache, and active state
  Future<void> togglePermission(String role, String key, bool value) async {
    if (isClosed || key.isEmpty) return;
    final cleanRole = role.toLowerCase().trim();

    // ignore: avoid_print
    print('DEBUG: Toggling permission - role: $cleanRole, key: $key, value: $value');

    // 1. Optimistic Updates
    final oldPermissions = List<PermissionItemEntity>.from(state.permissions);
    final oldUserPermissions = Map<String, bool>.from(state.userPermissions);

    final updatedPermissions = state.permissions.map((p) {
      if (p.key == key) return p.copyWith(isEnabled: value);
      return p;
    }).toList();

    final isForCurrentUser = cleanRole == (state.userRole ?? '').toLowerCase().trim();
    final updatedUserPermissions = Map<String, bool>.from(state.userPermissions);
    if (isForCurrentUser || cleanRole == state.selectedRole) {
      updatedUserPermissions[key] = value;
    }

    // Update Local Cache Immediately
    _saveToCache(cleanRole, updatedPermissions);

    emit(state.copyWith(
      permissions: updatedPermissions,
      userPermissions: updatedUserPermissions,
    ));

    // 2. Remote DB Update
    final result = await updateRolePermissionUseCase(cleanRole, key, value);
    if (isClosed) return;

    result.fold(
      (failure) {
        // ignore: avoid_print
        print('DEBUG: Update failure: ${failure.message}');
        // Rollback on failure
        _saveToCache(cleanRole, oldPermissions);
        emit(state.copyWith(
          permissions: oldPermissions,
          userPermissions: oldUserPermissions,
          status: PermissionsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (_) {
        // ignore: avoid_print
        print('DEBUG: Update success for key: $key in role: $cleanRole');
      },
    );
  }

  void _saveToCache(String role, List<PermissionItemEntity> list) {
    if (cacheService == null) return;
    try {
      final jsonList = list.map((p) {
        return PermissionItemModel(
          key: p.key,
          nameAr: p.nameAr,
          nameEn: p.nameEn,
          category: p.category,
          descriptionAr: p.descriptionAr,
          descriptionEn: p.descriptionEn,
          isEnabled: p.isEnabled,
        ).toJson();
      }).toList();
      cacheService!.setJson(_getCacheKey(role), jsonList);
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: Cache save error: $e');
    }
  }

  /// Evaluates permission dynamically
  bool hasPermission(String key, {String? userRole}) {
    final activeRole = (userRole ?? state.userRole ?? '').toLowerCase().trim();

    // 1. Level 0 Bypass: Super Admin & Lounge Owner always have full access
    if (activeRole == 'superadmin' || activeRole == 'super_admin' || activeRole == 'owner') {
      return true;
    }

    // 2. Check active user permissions map first
    if (state.userPermissions.containsKey(key)) {
      return state.userPermissions[key] ?? false;
    }

    // 3. Check selected permissions list if matching
    try {
      final p = state.permissions.firstWhere((item) => item.key == key);
      return p.isEnabled;
    } catch (_) {}

    // 4. Default Fallbacks if key not configured
    if (activeRole == 'manager') return true;

    // Restricted keys for cashier by default
    final restrictedForCashier = [
      'staff_management',
      'financials_view',
      'reports_view',
      'shifts_approve',
      'menu_edit_prices',
      'menu_manage_items',
      'rooms_manage',
      'marketing_manage',
      'lounge_profile_edit',
      'kyc_manage',
      'view_payouts_global',
    ];

    if (activeRole == 'cashier' && restrictedForCashier.contains(key)) {
      return false;
    }

    return true;
  }
}
