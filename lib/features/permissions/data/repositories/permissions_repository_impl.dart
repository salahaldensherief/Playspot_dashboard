import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/core/utils/repository_helper.dart';
import '../../domain/entities/permission_item_entity.dart';
import '../../domain/repositories/permissions_repository.dart';
import '../data_sources/permissions_remote_data_source.dart';

class PermissionsRepositoryImpl with RepositoryHelper implements PermissionsRepository {
  final PermissionsRemoteSource remoteSource;

  PermissionsRepositoryImpl(this.remoteSource);

  @override
  Future<Either<Failure, List<PermissionItemEntity>>> getRolePermissions(String role, {String? loungeId}) async {
    return await callRepository(() => remoteSource.getRolePermissions(role, loungeId: loungeId));
  }

  @override
  Future<Either<Failure, PaginatedResult<PermissionItemEntity>>> getLoungeRolePermissionsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 50,
  }) async {
    return await callRepository(() async {
      final res = await remoteSource.getLoungeRolePermissionsPage(loungeId: loungeId, page: page, pageSize: pageSize);
      return PaginatedResult<PermissionItemEntity>(
        items: res.items,
        totalCount: res.totalCount,
        page: res.page,
        pageSize: res.pageSize,
      );
    });
  }

  @override
  Future<Either<Failure, void>> updateRolePermission(String role, String permissionKey, bool isEnabled, {String? loungeId}) async {
    return await callRepository(() => remoteSource.updateRolePermission(role, permissionKey, isEnabled, loungeId: loungeId));
  }
}
