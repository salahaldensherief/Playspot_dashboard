import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../domain/entities/app_status_entity.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/system_repository.dart';
import '../datasources/system_remote_data_source.dart';
import '../models/app_status_model.dart';
import '../models/announcement_model.dart';

class SystemRepositoryImpl implements SystemRepository {
  final SystemRemoteDataSource remoteDataSource;

  SystemRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AppStatusEntity>> getAppStatus() async {
    try {
      final status = await remoteDataSource.getAppStatus();
      return Right(status);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMaintenanceMode({
    required bool isMaintenanceMode,
    required String maintenanceMessageAr,
    required String maintenanceMessageEn,
    DateTime? expectedEndTime,
  }) async {
    try {
      final current = await remoteDataSource.getAppStatus();
      final updated = current.copyWith(
        isMaintenanceMode: isMaintenanceMode,
        maintenanceMessageAr: maintenanceMessageAr,
        maintenanceMessageEn: maintenanceMessageEn,
        expectedEndTime: expectedEndTime,
      );

      await remoteDataSource.updateAppStatus(AppStatusModel.fromEntity(updated));
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAppVersions(AppStatusEntity appStatus) async {
    try {
      final model = AppStatusModel.fromEntity(appStatus);
      await remoteDataSource.updateAppStatus(model);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AnnouncementEntity>>> getAnnouncements() async {
    try {
      final announcements = await remoteDataSource.getAnnouncements();
      return Right(announcements);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createAnnouncement(AnnouncementEntity announcement) async {
    try {
      final model = AnnouncementModel.fromEntity(announcement);
      await remoteDataSource.createAnnouncement(model);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateAnnouncement(String id) async {
    try {
      await remoteDataSource.deactivateAnnouncement(id);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
