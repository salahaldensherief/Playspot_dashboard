import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../../../core/utils/paginated_result.dart';
import '../models/permission_item_model.dart';
import 'default_role_permissions_catalog.dart';
import 'permissions_remote_data_source.dart';

class PermissionsRemoteSourceImpl implements PermissionsRemoteSource {
  final SupabaseClient _supabase;

  PermissionsRemoteSourceImpl(this._supabase);

  @override
  Future<List<PermissionItemModel>> getRolePermissions(String role, {String? loungeId}) async {
    final cleanRole = role.toLowerCase().trim();
    final cleanLoungeId = loungeId?.trim();

    // 1. Primary path: Query lounge_role_permissions table directly for this specific lounge
    if (cleanLoungeId != null && cleanLoungeId.isNotEmpty) {
      try {
        final List<dynamic> loungePerms = await _supabase
            .from('lounge_role_permissions')
            .select('permission_key, is_enabled')
            .eq('lounge_id', cleanLoungeId)
            .eq('role', cleanRole);

        if (loungePerms.isNotEmpty) {
          AppLogger.debug('PermissionsRemoteSource: Loaded ${loungePerms.length} permissions from lounge_role_permissions for lounge $cleanLoungeId');
          final Map<String, bool> loungeOverrides = {
            for (var p in loungePerms)
              if (p['permission_key'] != null)
                p['permission_key'].toString(): p['is_enabled'] == true
          };

          final defaults = DefaultRolePermissionsCatalog.getDefaultPermissionsForRole(cleanRole);
          return defaults.map((item) {
            if (loungeOverrides.containsKey(item.key)) {
              return PermissionItemModel(
                key: item.key,
                nameAr: item.nameAr,
                nameEn: item.nameEn,
                category: item.category,
                descriptionAr: item.descriptionAr,
                descriptionEn: item.descriptionEn,
                isEnabled: loungeOverrides[item.key] ?? false,
              );
            }
            return item;
          }).toList();
        }
      } catch (e) {
        AppLogger.warning('PermissionsRemoteSource: lounge_role_permissions query failed: $e');
      }
    }

    // 2. Fallback 1: Query global role_permissions RPC
    try {
      final response = await _supabase.rpc('get_role_permissions', params: {
        'p_role': cleanRole,
      });
      if (response != null && response is List && response.isNotEmpty) {
        return response
            .map((json) => PermissionItemModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    } catch (e) {
      AppLogger.warning('PermissionsRemoteSource: RPC get_role_permissions failed: $e');
    }

    // 3. Fallback 2: Query role_permissions table directly
    try {
      final tableResponse = await _supabase
          .from('role_permissions')
          .select('*, permissions(*)')
          .eq('role', cleanRole);
      if (tableResponse.isNotEmpty) {
        return tableResponse.map((json) {
          final perm = json['permissions'] as Map<String, dynamic>? ?? {};
          return PermissionItemModel(
            key: json['permission_key']?.toString() ?? perm['key']?.toString() ?? '',
            nameAr: perm['name_ar']?.toString() ?? json['permission_key']?.toString() ?? '',
            nameEn: perm['name_en']?.toString() ?? json['permission_key']?.toString() ?? '',
            category: perm['category']?.toString() ?? 'General',
            descriptionAr: perm['description_ar']?.toString() ?? '',
            descriptionEn: perm['description_en']?.toString() ?? '',
            isEnabled: json['is_enabled'] ?? false,
          );
        }).toList();
      }
    } catch (tableError) {
      AppLogger.warning('PermissionsRemoteSource: Fallback table select failed: $tableError');
    }

    // 4. Default static permissions list fallback so UI is NEVER EMPTY!
    return DefaultRolePermissionsCatalog.getDefaultPermissionsForRole(cleanRole);
  }

  @override
  Future<PaginatedResult<PermissionItemModel>> getLoungeRolePermissionsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      return PaginatedResult.empty(requestedPage: page, requestedPageSize: pageSize);
    }

    final clampedPageSize = pageSize.clamp(1, 100);
    final validPage = page < 1 ? 1 : page;

    try {
      final response = await _supabase.rpc('get_lounge_role_permissions_page', params: {
        'p_lounge_id': cleanLoungeId,
        'p_page': validPage,
        'p_page_size': clampedPageSize,
      });

      return PaginatedResult.fromRpcResponse<PermissionItemModel>(
        response,
        mapper: (json) => PermissionItemModel.fromJson(json),
        requestedPage: validPage,
        requestedPageSize: clampedPageSize,
      );
    } catch (e) {
      AppLogger.warning('PermissionsRemoteSource: get_lounge_role_permissions_page failed: $e');
      final fallbackList = await getRolePermissions('manager', loungeId: cleanLoungeId);
      return PaginatedResult(
        items: fallbackList,
        totalCount: fallbackList.length,
        page: validPage,
        pageSize: clampedPageSize,
      );
    }
  }

  @override
  Future<void> updateRolePermission(String role, String permissionKey, bool isEnabled, {String? loungeId}) async {
    final cleanRole = role.toLowerCase().trim();
    final cleanLoungeId = loungeId?.trim();

    AppLogger.debug('Supabase updateRolePermission: role=$cleanRole, key=$permissionKey, enabled=$isEnabled, loungeId=$cleanLoungeId');

    // 1. Primary path: Save to lounge_role_permissions table
    if (cleanLoungeId != null && cleanLoungeId.isNotEmpty) {
      try {
        final result = await _supabase
            .from('lounge_role_permissions')
            .upsert(
              {
                'lounge_id': cleanLoungeId,
                'role': cleanRole,
                'permission_key': permissionKey,
                'is_enabled': isEnabled,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              },
              onConflict: 'lounge_id,role,permission_key',
            )
            .select();
        AppLogger.debug('Saved permission in lounge_role_permissions: $result');
        return;
      } catch (e) {
        AppLogger.warning('PermissionsRemoteSource: upsert lounge_role_permissions with onConflict failed: $e. Trying without onConflict.');
        try {
          final result = await _supabase
              .from('lounge_role_permissions')
              .upsert(
                {
                  'lounge_id': cleanLoungeId,
                  'role': cleanRole,
                  'permission_key': permissionKey,
                  'is_enabled': isEnabled,
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                },
              )
              .select();
          AppLogger.debug('Saved permission in lounge_role_permissions (fallback): $result');
          return;
        } catch (e2) {
          AppLogger.error('PermissionsRemoteSource: Fallback lounge_role_permissions upsert failed: $e2');
        }
      }
    }

    // 2. Global fallback (role_permissions)
    try {
      await _supabase.rpc('update_role_permission', params: {
        'p_role': cleanRole,
        'p_permission_key': permissionKey,
        'p_is_enabled': isEnabled,
      });
    } catch (e) {
      AppLogger.warning('PermissionsRemoteSource: RPC update_role_permission failed: $e. Falling back to role_permissions upsert.');
      try {
        await _supabase.from('role_permissions').upsert({
          'role': cleanRole,
          'permission_key': permissionKey,
          'is_enabled': isEnabled,
        }, onConflict: 'role,permission_key');
      } catch (e2) {
        AppLogger.error('PermissionsRemoteSource: Table upsert failed: $e2');
      }
    }
  }
}
