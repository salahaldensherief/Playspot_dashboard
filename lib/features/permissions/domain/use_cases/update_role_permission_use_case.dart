import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../repositories/permissions_repository.dart';

class UpdateRolePermissionUseCase {
  final PermissionsRepository repository;

  UpdateRolePermissionUseCase(this.repository);

  Future<Either<Failure, void>> call(String role, String permissionKey, bool isEnabled) async {
    return await repository.updateRolePermission(role, permissionKey, isEnabled);
  }
}
