import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/live_shift_overview_entity.dart';
import '../../domain/repositories/shift_repository.dart';
import '../data_source/remote/shift_remote_data_source.dart';

class ShiftRepositoryImpl with RepositoryHelper implements ShiftRepository {
  final ShiftRemoteSource remoteSource;

  ShiftRepositoryImpl(this.remoteSource);

  @override
  Future<Either<Failure, ShiftEntity?>> getActiveShift(String loungeId) async {
    return await callRepository(() => remoteSource.getActiveShift(loungeId));
  }

  @override
  Future<Either<Failure, LiveShiftOverviewEntity>> getLoungeLiveShiftOverview(String loungeId) async {
    return await callRepository(() => remoteSource.getLoungeLiveShiftOverview(loungeId));
  }

  @override
  Future<Either<Failure, void>> openShift(String loungeId, double startingCash) async {
    return await callRepository(() => remoteSource.openShift(loungeId, startingCash));
  }

  @override
  Future<Either<Failure, ShiftEntity>> closeShift(String shiftId, double actualCash, String? notes) async {
    return await callRepository(() => remoteSource.closeShift(shiftId, actualCash, notes));
  }

  @override
  Future<Either<Failure, List<ShiftEntity>>> getShiftHistory({String? loungeId}) async {
    return await callRepository(() => remoteSource.getShifts(loungeId: loungeId));
  }

  @override
  Future<Either<Failure, void>> approveShift(String shiftId, String managerId, String? notes) async {
    return await callRepository(() => remoteSource.approveShift(shiftId, managerId, notes));
  }
}
