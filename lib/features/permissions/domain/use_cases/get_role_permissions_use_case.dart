import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/permission_item_entity.dart';
import '../repositories/permissions_repository.dart';

class GetRolePermissionsUseCase {
  final PermissionsRepository repository;

  GetRolePermissionsUseCase(this.repository);

  Future<Either<Failure, List<PermissionItemEntity>>> call(String role) async {
    return await repository.getRolePermissions(role);
  }
}
