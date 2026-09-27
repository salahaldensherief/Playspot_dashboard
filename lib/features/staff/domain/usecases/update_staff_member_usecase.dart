import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/staff_repository.dart';

class UpdateStaffParams extends Equatable {
  final String staffId;
  final Map<String, dynamic> data;

  const UpdateStaffParams({required this.staffId, required this.data});

  @override
  List<Object?> get props => [staffId, data];
}

class UpdateStaffMemberUseCase implements UseCase<void, UpdateStaffParams> {
  final StaffRepository repository;

  UpdateStaffMemberUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateStaffParams params) {
    return repository.updateStaffMember(params.staffId, params.data);
  }
}
