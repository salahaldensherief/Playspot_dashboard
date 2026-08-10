import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import '../repositories/admin_management_repository.dart';

class GetAdminsUseCase {
  final AdminManagementRepository repository;

  GetAdminsUseCase(this.repository);

  Future<Either<Failure, List<UserEntity>>> call() {
    return repository.getAdmins();
  }
}
