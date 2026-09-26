import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
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

  String? _activeLoungeId;

  PermissionsCubit({
    required this.getRolePermissionsUseCase,
    required this.updateRolePermissionUseCase,
    this.cacheService,
  }) : super(PermissionsState.initial());

  String _getCacheKey(String role, {String? loungeId}) {
    final cleanRole = role.toLowerCase().trim();
    final lId = loungeId ?? _activeLoungeId ?? '';
    return 'permissions_cache_${cleanRole}_$lId';
  }

  void setActiveLoungeId(String? loungeId) {
    if (loungeId != null && loungeId.isNotEmpty) {
      _activeLoungeId = loungeId;
    }
  }

  /// Loads permissions for the active logged-in user and populates local state & cache
  Future<void> loadUserPermissions(String role, {String? loungeId}) async {
    if (isClosed) return;
    if (loungeId != null && loungeId.isNotEmpty) {
      _activeLoungeId = loungeId;
    }
    final cleanRole = role.toLowerCase().trim();
    final effectiveLoungeId = loungeId ?? _activeLoungeId;

    AppLogger.debug('Loading user permissions for active role: $cleanRole, loungeId: $effectiveLoungeId');

    emit(state.copyWith(userRole: cleanRole));

    // 1. Instant Cache-First Load
    final cachedData = cacheService?.getJson(_getCacheKey(cleanRole, loungeId: effectiveLoungeId));
    if (cachedData != null && cachedData is List && cachedData.isNotEmpty) {
      try {
        final cachedList = cachedData
            .map((e) => PermissionItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final userPermMap = {for (var p in cachedList) p.key: p.isEnabled};
        emit(state.copyWith(userPermissions: userPermMap));
        AppLogger.debug('Loaded ${userPermMap.length} permissions from local cache for $cleanRole');
      } catch (e) {
        AppLogger.warning('Error parsing cached permissions: $e');
      }
    }

    // 2. Fetch from Remote DB to Sync
    final result = await getRolePermissionsUseCase(cleanRole, loungeId: effectiveLoungeId);
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning('User permissions fetch failure: ${failure.message}');
      },
      (permissions) {
        final userPermMap = {for (var p in permissions) p.key: p.isEnabled};
        _saveToCache(cleanRole, permissions, loungeId: effectiveLoungeId);
        emit(state.copyWith(
          userPermissions: userPermMap,
          status: PermissionsStatus.success,
        ));
        AppLogger.debug('Synced ${permissions.length} user permissions from remote DB for $cleanRole');
      },
    );
  }

  /// Fetches permissions for a specific role to display/edit in settings tab
  Future<void> fetchPermissions(String role, {String? loungeId}) async {
    if (isClosed) return;
    if (loungeId != null && loungeId.isNotEmpty) {
      _activeLoungeId = loungeId;
    }
    final cleanRole = role.toLowerCase().trim();
    final effectiveLoungeId = loungeId ?? _activeLoungeId;

    AppLogger.debug('Fetching permissions for role: $cleanRole, loungeId: $effectiveLoungeId');

    emit(state.copyWith(status: PermissionsStatus.loading, selectedRole: cleanRole));

    // 1. Instant Cache-First Load
    final cachedData = cacheService?.getJson(_getCacheKey(cleanRole, loungeId: effectiveLoungeId));
    if (cachedData != null && cachedData is List && cachedData.isNotEmpty) {
      try {
        final cachedList = cachedData
            .map((e) => PermissionItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        emit(state.copyWith(permissions: cachedList));
      } catch (_) {}
    }

    // 2. Remote Fetch
    final result = await getRolePermissionsUseCase(cleanRole, loungeId: effectiveLoungeId);
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning('Fetch failure: ${failure.message}');
        emit(state.copyWith(status: PermissionsStatus.failure, errorMessage: failure.message));
      },
      (permissions) {
        AppLogger.debug('Fetched ${permissions.length} permissions for $cleanRole');
        _saveToCache(cleanRole, permissions, loungeId: effectiveLoungeId);

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

  /// Fetches paginated lounge role permissions
  Future<void> fetchLoungeRolePermissionsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 50,
  }) async {
    if (isClosed || loungeId.trim().isEmpty) return;
    _activeLoungeId = loungeId.trim();

    emit(state.copyWith(status: PermissionsStatus.loading));

    final result = await getRolePermissionsUseCase.repository.getLoungeRolePermissionsPage(
      loungeId: _activeLoungeId!,
      page: page,
      pageSize: pageSize,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning('Fetch lounge role permissions page failure: ${failure.message}');
        emit(state.copyWith(status: PermissionsStatus.failure, errorMessage: failure.message));
      },
      (paginated) {
        emit(state.copyWith(
          status: PermissionsStatus.success,
          permissions: paginated.items,
          page: paginated.page,
          pageSize: paginated.pageSize,
          totalCount: paginated.totalCount,
        ));
      },
    );
  }

  /// Toggles a permission for a role, updates remote DB, cache, and active state
  Future<void> togglePermission(String role, String key, bool value, {String? loungeId}) async {
    if (isClosed || key.isEmpty) return;
    if (loungeId != null && loungeId.isNotEmpty) {
      _activeLoungeId = loungeId;
    }
    final cleanRole = role.toLowerCase().trim();
    final effectiveLoungeId = loungeId ?? _activeLoungeId;

    AppLogger.debug('Toggling permission - role: $cleanRole, key: $key, value: $value, loungeId: $effectiveLoungeId');

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
    _saveToCache(cleanRole, updatedPermissions, loungeId: effectiveLoungeId);

    emit(state.copyWith(
      permissions: updatedPermissions,
      userPermissions: updatedUserPermissions,
    ));

    // 2. Remote DB Update
    final result = await updateRolePermissionUseCase(cleanRole, key, value, loungeId: effectiveLoungeId);
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning('Update failure: ${failure.message}');
        // Rollback on failure
        _saveToCache(cleanRole, oldPermissions, loungeId: effectiveLoungeId);
        emit(state.copyWith(
          permissions: oldPermissions,
          userPermissions: oldUserPermissions,
          status: PermissionsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (_) {
        AppLogger.debug('Update success for key: $key in role: $cleanRole');
      },
    );
  }

  void _saveToCache(String role, List<PermissionItemEntity> list, {String? loungeId}) {
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
      cacheService!.setJson(_getCacheKey(role, loungeId: loungeId), jsonList);
    } catch (e) {
      AppLogger.warning('Cache save error: $e');
    }
  }

  String _normalizeRole(String rawRole) {
    final clean = rawRole.toLowerCase().trim();
    if (clean == 'superadmin' || clean == 'super_admin') return 'super_admin';
    if (clean == 'owner' || clean == 'lounge_owner') return 'owner';
    if (clean == 'manager' || clean == 'lounge_admin' || clean == 'admin') return 'manager';
    if (clean == 'cashier') return 'cashier';
    if (clean == 'staff') return 'staff';
    return clean;
  }

  /// Evaluates permission dynamically using strict deny-by-default RBAC principles.
  bool hasPermission(String key, {String? userRole}) {
    if (key.isEmpty) return false;
    final activeRole = _normalizeRole(userRole ?? state.userRole ?? '');

    // 1. Level 0 Bypass: Super Admin & Lounge Owner always have full access
    if (activeRole == 'super_admin' || activeRole == 'owner') {
      return true;
    }

    // 2. Check active user permissions map first if explicitly configured in DB
    if (state.userPermissions.containsKey(key)) {
      return state.userPermissions[key] ?? false;
    }

    // 3. Check selected permissions list if key configured
    try {
      final p = state.permissions.firstWhere((item) => item.key == key);
      return p.isEnabled;
    } catch (_) {}

    // 4. Strict Allowlist for Manager role (Denies super-admin / platform owner keys if unconfigured)
    const allowedForManager = [
      'menu_view',
      'menu_manage_items',
      'menu_edit_prices',
      'extras_update_stock',
      'pos_checkout',
      'bookings_view',
      'bookings_create',
      'bookings_manage',
      'bookings_cancel',
      'rooms_view',
      'rooms_manage',
      'shift_start',
      'shift_close',
      'shift_view_expected_cash',
      'shifts_view',
      'shifts_approve',
      'booking_discount_apply',
      'financials_view',
      'reports_view',
      'marketing_manage',
      'staff_management',
      'lounge_profile_edit',
      'lounge_toggle_status',
      'reviews_view',
      'canteen_orders_view',
      'canteen_orders_process',
      'service_calls_view',
      'service_calls_process',
      'checkout_process',
      'cash_register_open',
      'cash_register_close',
      'cash_drop_record',
      'expense_record',
      'shift_view',
      'extras_view',
    ];

    if (activeRole == 'manager') {
      return allowedForManager.contains(key);
    }

    // 5. Strict Allowlist for Cashier role
    const allowedForCashier = [
      'bookings_view',
      'bookings_create',
      'bookings_manage',
      'bookings_cancel',
      'checkout_process',
      'cash_register_open',
      'cash_register_close',
      'cash_drop_record',
      'expense_record',
      'shift_view',
      'canteen_orders_view',
      'canteen_orders_process',
      'service_calls_view',
      'service_calls_process',
      'extras_view',
      'rooms_view',
    ];

    if (activeRole == 'cashier') {
      return allowedForCashier.contains(key);
    }

    // 6. Strict Deny-By-Default: Any unhandled role or unlisted key returns false
    return false;
  }
}
