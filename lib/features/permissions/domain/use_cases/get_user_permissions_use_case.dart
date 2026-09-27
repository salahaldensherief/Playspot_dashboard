import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/permission_item_entity.dart';
import '../repositories/permissions_repository.dart';

class GetUserPermissionsUseCase {
  final PermissionsRepository repository;
  GetUserPermissionsUseCase(this.repository);

  Future<Either<Failure, List<PermissionItemEntity>>> call({String? loungeId}) {
    return repository.getUserPermissions(loungeId: loungeId);
  }
}
