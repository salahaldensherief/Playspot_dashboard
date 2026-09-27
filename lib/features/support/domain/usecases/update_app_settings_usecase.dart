import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_settings_entity.dart';
import '../repositories/support_repository.dart';

class UpdateAppSettingsUseCase {
  final SupportRepository repository;

  UpdateAppSettingsUseCase(this.repository);

  Future<Either<Failure, void>> call(AppSettingsEntity settings) {
    return repository.updateAppSettings(settings);
  }
}
