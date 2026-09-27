import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../../../core/utils/paginated_result.dart';
import '../models/permission_item_model.dart';
import 'permissions_remote_data_source.dart';

class PermissionsRemoteSourceImpl implements PermissionsRemoteSource {
  final SupabaseClient _supabase;

  PermissionsRemoteSourceImpl(this._supabase);

  @override
  Future<List<PermissionItemModel>> getUserPermissions({
    String? loungeId,
  }) async {
    final response = await _supabase.rpc(
      'get_my_permissions',
      params: {'p_lounge_id': loungeId},
    );
    return _parsePermissions(response);
  }

  @override
  Future<List<PermissionItemModel>> getRolePermissions(
    String role, {
    String? loungeId,
  }) async {
    final response = await _supabase.rpc(
      'get_lounge_role_permission_catalog',
      params: {'p_lounge_id': loungeId, 'p_role': role.toLowerCase().trim()},
    );
    return _parsePermissions(response);
  }

  List<PermissionItemModel> _parsePermissions(dynamic response) {
    return (response as List)
        .map(
          (item) => PermissionItemModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<PaginatedResult<PermissionItemModel>> getLoungeRolePermissionsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      return PaginatedResult.empty(
        requestedPage: page,
        requestedPageSize: pageSize,
      );
    }

    final clampedPageSize = pageSize.clamp(1, 100);
    final validPage = page < 1 ? 1 : page;

    final response = await _supabase.rpc(
      'get_lounge_role_permissions_page',
      params: {
        'p_lounge_id': cleanLoungeId,
        'p_page': validPage,
        'p_page_size': clampedPageSize,
      },
    );
    return PaginatedResult.fromRpcResponse<PermissionItemModel>(
      response,
      mapper: PermissionItemModel.fromJson,
      requestedPage: validPage,
      requestedPageSize: clampedPageSize,
    );
  }

  @override
  Future<void> updateRolePermission(
    String role,
    String permissionKey,
    bool isEnabled, {
    String? loungeId,
  }) async {
    final cleanRole = role.toLowerCase().trim();
    final cleanLoungeId = loungeId?.trim();

    AppLogger.debug(
      'Supabase updateRolePermission: role=$cleanRole, key=$permissionKey, enabled=$isEnabled, loungeId=$cleanLoungeId',
    );

    await _supabase.rpc(
      'update_role_permission',
      params: {
        'p_role': cleanRole,
        'p_permission_key': permissionKey,
        'p_is_enabled': isEnabled,
        'p_lounge_id': cleanLoungeId != null && cleanLoungeId.isNotEmpty
            ? cleanLoungeId
            : null,
      },
    );
  }
}
