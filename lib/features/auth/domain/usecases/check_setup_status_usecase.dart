import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/usecases/base_usecase.dart';
import '../repositories/auth_repository.dart';

class CheckSetupStatusUseCase extends UseCase<bool, String> {
  final AuthRepository repository;

  CheckSetupStatusUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String params) async {
    return await repository.checkSetupStatus(params);
  }
}
