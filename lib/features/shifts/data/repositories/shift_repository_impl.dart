import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/repository_helper.dart';
import '../models/shift_expense_model.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/live_shift_overview_entity.dart';
import '../../domain/entities/shift_expense_entity.dart';
import '../../domain/repositories/shift_repository.dart';
import '../data_sources/shift_remote_data_source.dart';

class ShiftRepositoryImpl with RepositoryHelper implements ShiftRepository {
  final ShiftRemoteDataSource remoteDataSource;

  ShiftRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, ShiftEntity?>> getActiveShift(String loungeId) async {
    return await callRepository(() => remoteDataSource.getActiveShift(loungeId));
  }

  @override
  Future<Either<Failure, LiveShiftOverviewEntity>> getLoungeLiveShiftOverview(String loungeId) async {
    return await callRepository(() => remoteDataSource.getLoungeLiveShiftOverview(loungeId));
  }

  @override
  Future<Either<Failure, void>> openShift(String loungeId, double startingCash) async {
    return await callRepository(() => remoteDataSource.openShift(loungeId, startingCash));
  }

  @override
  Future<Either<Failure, ShiftEntity>> closeShift(String shiftId, double actualCash, String? notes) async {
    return await callRepository(() => remoteDataSource.closeShift(shiftId, actualCash, notes));
  }

  @override
  Future<Either<Failure, List<ShiftEntity>>> getShiftHistory({String? loungeId}) async {
    return await callRepository(() => remoteDataSource.getShifts(loungeId: loungeId));
  }

  @override
  Future<Either<Failure, void>> approveShift(String shiftId, String managerId, String? notes) async {
    return await callRepository(() => remoteDataSource.approveShift(shiftId, managerId, notes));
  }

  @override
  Future<Either<Failure, void>> addShiftExpense(ShiftExpenseEntity expense) async {
    final model = ShiftExpenseModel(
      id: expense.id,
      shiftId: expense.shiftId,
      loungeId: expense.loungeId,
      amount: expense.amount,
      type: expense.type,
      reason: expense.reason,
      createdBy: expense.createdBy,
      createdByName: expense.createdByName,
      createdAt: expense.createdAt,
    );
    return await callRepository(() => remoteDataSource.addShiftExpense(model));
  }

  @override
  Future<Either<Failure, List<ShiftExpenseEntity>>> fetchShiftExpenses(String shiftId) async {
    return await callRepository(() => remoteDataSource.fetchShiftExpenses(shiftId));
  }
}
