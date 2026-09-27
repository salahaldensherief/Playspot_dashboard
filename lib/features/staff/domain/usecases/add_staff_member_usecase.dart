import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../../data/models/staff_params.dart';
import '../repositories/staff_repository.dart';

class AddStaffMemberUseCase implements UseCase<void, AddStaffParams> {
  final StaffRepository repository;

  AddStaffMemberUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddStaffParams params) {
    return repository.addStaffMember(params);
  }
}
