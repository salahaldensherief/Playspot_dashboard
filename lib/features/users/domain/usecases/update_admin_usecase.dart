import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/usecases/base_usecase.dart';
import '../repositories/admin_management_repository.dart';

class UpdateAdminParams extends Equatable {
  final String adminId;
  final String? name;
  final String? email;

  const UpdateAdminParams({
    required this.adminId,
    this.name,
    this.email,
  });

  @override
  List<Object?> get props => [adminId, name, email];
}

class UpdateAdminUseCase implements UseCase<void, UpdateAdminParams> {
  final AdminManagementRepository repository;

  UpdateAdminUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateAdminParams params) {
    return repository.updateAdmin(
      params.adminId,
      name: params.name,
      email: params.email,
    );
  }
}
