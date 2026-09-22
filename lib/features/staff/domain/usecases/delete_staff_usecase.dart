import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/staff_repository.dart';

class DeleteStaffUseCase implements UseCase<void, String> {
  final StaffRepository repository;

  DeleteStaffUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String staffId) {
    return repository.deleteStaff(staffId);
  }
}
