import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/permission_item_model.dart';

abstract class PermissionsRemoteSource {
  Future<List<PermissionItemModel>> getRolePermissions(String role);
  Future<void> updateRolePermission(String role, String permissionKey, bool isEnabled);
}

class PermissionsRemoteSourceImpl implements PermissionsRemoteSource {
  final SupabaseClient _supabase;

  PermissionsRemoteSourceImpl(this._supabase);

  @override
  Future<List<PermissionItemModel>> getRolePermissions(String role) async {
    final response = await _supabase.rpc('get_role_permissions', params: {
      'p_role': role,
    });
    
    return (response as List).map((json) => PermissionItemModel.fromJson(json)).toList();
  }

  @override
  Future<void> updateRolePermission(String role, String permissionKey, bool isEnabled) async {
    await _supabase.rpc('update_role_permission', params: {
      'p_role': role,
      'p_permission_key': permissionKey,
      'p_is_enabled': isEnabled,
    });
  }
}
