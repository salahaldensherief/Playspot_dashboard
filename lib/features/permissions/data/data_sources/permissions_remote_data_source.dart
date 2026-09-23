import '../../../../core/utils/paginated_result.dart';
import '../models/permission_item_model.dart';

abstract class PermissionsRemoteSource {
  Future<List<PermissionItemModel>> getRolePermissions(String role, {String? loungeId});
  Future<PaginatedResult<PermissionItemModel>> getLoungeRolePermissionsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 50,
  });
  Future<void> updateRolePermission(String role, String permissionKey, bool isEnabled, {String? loungeId});
}
