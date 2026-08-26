import '../../domain/entities/shift_entity.dart';
import '../../domain/repositories/shift_repository.dart';
import '../data_sources/shift_remote_data_source.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final ShiftRemoteDataSource remoteDataSource;

  ShiftRepositoryImpl(this.remoteDataSource);

  @override
  Future<ShiftEntity?> getCurrentShift(String loungeId) async {
    return await remoteDataSource.getCurrentShift(loungeId);
  }

  @override
  Future<void> openShift(String loungeId, double startingCash) async {
    await remoteDataSource.openShift(loungeId, startingCash);
  }

  @override
  Future<void> closeShift(String shiftId, double actualCashCounted, String? notes) async {
    await remoteDataSource.closeShift(shiftId, actualCashCounted, notes);
  }

  @override
  Future<List<ShiftEntity>> getShiftHistory({String? loungeId}) async {
    return await remoteDataSource.getShiftHistory(loungeId: loungeId);
  }
}
