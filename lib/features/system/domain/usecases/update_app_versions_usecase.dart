import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/app_status_entity.dart';
import '../repositories/system_repository.dart';

class UpdateAppVersionsUseCase {
  final SystemRepository repository;

  UpdateAppVersionsUseCase(this.repository);

  Future<Either<Failure, void>> call(AppStatusEntity appStatus) async {
    return await repository.updateAppVersions(appStatus);
  }
}
