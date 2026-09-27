import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/staff_repository.dart';

class UpdateStaffStatusParams extends Equatable {
  final String staffId;
  final bool isActive;

  const UpdateStaffStatusParams({required this.staffId, required this.isActive});

  @override
  List<Object?> get props => [staffId, isActive];
}

class UpdateStaffStatusUseCase implements UseCase<void, UpdateStaffStatusParams> {
  final StaffRepository repository;

  UpdateStaffStatusUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateStaffStatusParams params) {
    return repository.updateStaffStatus(params.staffId, params.isActive);
  }
}
