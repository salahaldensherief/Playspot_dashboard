import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_settings_entity.dart';
import '../repositories/support_repository.dart';

class GetAppSettingsUseCase {
  final SupportRepository repository;

  GetAppSettingsUseCase(this.repository);

  Future<Either<Failure, AppSettingsEntity>> call() {
    return repository.getAppSettings();
  }
}
