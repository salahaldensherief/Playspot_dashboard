import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/repository_helper.dart';
import '../../domain/entities/permission_item_entity.dart';
import '../../domain/repositories/permissions_repository.dart';
import '../data_sources/permissions_remote_data_source.dart';

class PermissionsRepositoryImpl with RepositoryHelper implements PermissionsRepository {
  final PermissionsRemoteSource remoteSource;

  PermissionsRepositoryImpl(this.remoteSource);

  @override
  Future<Either<Failure, List<PermissionItemEntity>>> getRolePermissions(String role) async {
    return await callRepository(() => remoteSource.getRolePermissions(role));
  }

  @override
  Future<Either<Failure, void>> updateRolePermission(String role, String permissionKey, bool isEnabled) async {
    return await callRepository(() => remoteSource.updateRolePermission(role, permissionKey, isEnabled));
  }
}
