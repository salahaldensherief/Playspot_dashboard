import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import '../repositories/admin_management_repository.dart';

class CreateLoungeAdminUseCase {
  final AdminManagementRepository repository;

  CreateLoungeAdminUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String name,
    required String loungeName,
    String? city,
  }) {
    return repository.createLoungeAdmin(
      email: email,
      password: password,
      name: name,
      loungeName: loungeName,
      city: city,
    );
  }
}
