import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/app_status_entity.dart';
import '../entities/announcement_entity.dart';

abstract class SystemRepository {
  Future<Either<Failure, AppStatusEntity>> getAppStatus();
  
  Future<Either<Failure, void>> updateMaintenanceMode({
    required bool isMaintenanceMode,
    required String maintenanceMessageAr,
    required String maintenanceMessageEn,
    DateTime? expectedEndTime,
  });

  Future<Either<Failure, void>> updateAppVersions(AppStatusEntity appStatus);

  Future<Either<Failure, List<AnnouncementEntity>>> getAnnouncements();

  Future<Either<Failure, void>> createAnnouncement(AnnouncementEntity announcement);

  Future<Either<Failure, void>> deactivateAnnouncement(String id);
}
