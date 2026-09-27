import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/staff_entity.dart';
import '../repositories/staff_repository.dart';

class GetLoungeStaffUseCase implements UseCase<List<StaffEntity>, String> {
  final StaffRepository repository;

  GetLoungeStaffUseCase(this.repository);

  @override
  Future<Either<Failure, List<StaffEntity>>> call(String loungeId) {
    return repository.getLoungeStaff(loungeId);
  }
}
