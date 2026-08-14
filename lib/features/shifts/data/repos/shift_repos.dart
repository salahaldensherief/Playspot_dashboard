import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/repository_helper.dart';
import '../data_source/remote/shift_remote_data_source.dart';
import '../entities/shift_entity.dart';
import '../models/shift_params.dart';

abstract class ShiftRepository {
  Future<Either<Failure, List<ShiftEntity>>> getShifts({String? loungeId});
  Future<Either<Failure, ShiftEntity?>> getActiveShift(String cashierId);
  Future<Either<Failure, void>> openShift(OpenShiftParams params);
  Future<Either<Failure, ShiftEntity>> closeShift(CloseShiftParams params);
}

class ShiftRepositoryImpl with RepositoryHelper implements ShiftRepository {
  final ShiftRemoteSource _remoteSource;

  ShiftRepositoryImpl(this._remoteSource);

  @override
  Future<Either<Failure, List<ShiftEntity>>> getShifts({String? loungeId}) async {
    return await callRepository(() => _remoteSource.getShifts(loungeId: loungeId));
  }

  @override
  Future<Either<Failure, ShiftEntity?>> getActiveShift(String cashierId) async {
    return await callRepository(() => _remoteSource.getActiveShift(cashierId));
  }

  @override
  Future<Either<Failure, void>> openShift(OpenShiftParams params) async {
    return await callRepository(() => _remoteSource.openShift(params));
  }

  @override
  Future<Either<Failure, ShiftEntity>> closeShift(CloseShiftParams params) async {
    return await callRepository(() => _remoteSource.closeShift(params));
  }
}
