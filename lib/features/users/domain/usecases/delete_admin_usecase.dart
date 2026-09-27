import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/usecases/base_usecase.dart';
import '../repositories/admin_management_repository.dart';

class DeleteAdminUseCase implements UseCase<void, String> {
  final AdminManagementRepository repository;

  DeleteAdminUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String adminId) {
    return repository.deleteAdmin(adminId);
  }
}
