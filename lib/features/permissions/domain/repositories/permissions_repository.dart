import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/permission_item_entity.dart';

abstract class PermissionsRepository {
  Future<Either<Failure, List<PermissionItemEntity>>> getRolePermissions(String role);
  Future<Either<Failure, void>> updateRolePermission(String role, String permissionKey, bool isEnabled);
}
