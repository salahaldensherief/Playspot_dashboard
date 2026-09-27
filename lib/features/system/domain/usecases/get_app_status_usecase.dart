import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/app_status_entity.dart';
import '../repositories/system_repository.dart';

class GetAppStatusUseCase {
  final SystemRepository repository;

  GetAppStatusUseCase(this.repository);

  Future<Either<Failure, AppStatusEntity>> call() async {
    return await repository.getAppStatus();
  }
}
