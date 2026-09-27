import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../repositories/system_repository.dart';

class UpdateMaintenanceModeUseCase {
  final SystemRepository repository;

  UpdateMaintenanceModeUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required bool isMaintenanceMode,
    required String maintenanceMessageAr,
    required String maintenanceMessageEn,
    DateTime? expectedEndTime,
  }) async {
    return await repository.updateMaintenanceMode(
      isMaintenanceMode: isMaintenanceMode,
      maintenanceMessageAr: maintenanceMessageAr,
      maintenanceMessageEn: maintenanceMessageEn,
      expectedEndTime: expectedEndTime,
    );
  }
}
