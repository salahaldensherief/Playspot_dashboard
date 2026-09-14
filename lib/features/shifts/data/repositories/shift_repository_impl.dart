import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/repository_helper.dart';
import '../models/shift_expense_model.dart';
import '../models/shift_model.dart';
import '../models/shift_payment_model.dart';
import '../models/cashier_performance_model.dart';
import '../models/lounge_comparison_model.dart';
import '../models/shift_audit_log_model.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/live_shift_overview_entity.dart';
import '../../domain/entities/shift_expense_entity.dart';
import '../../domain/entities/shift_payment_entity.dart';
import '../../domain/entities/cashier_performance_entity.dart';
import '../../domain/entities/lounge_comparison_entity.dart';
import '../../domain/entities/shift_audit_log_entity.dart';
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
  Future<Either<Failure, void>> openShift(String loungeId, double startingCash, {String? notes}) async {
    return await callRepository(() => remoteDataSource.openShift(loungeId, startingCash, notes: notes));
  }

  @override
  Future<Either<Failure, void>> quickOpenShift(String loungeId, [double startingCash = 0.0, String? notes]) async {
    return await callRepository(() => remoteDataSource.openShift(loungeId, startingCash, notes: notes));
  }

  @override
  Future<Either<Failure, ShiftEntity>> closeShift(String shiftId, double actualCash, String? notes, {String? loungeId}) async {
    return await callRepository(() => remoteDataSource.closeShift(shiftId, actualCash, notes, loungeId: loungeId));
  }

  @override
  Future<Either<Failure, List<ShiftEntity>>> getShiftHistory({String? loungeId}) async {
    final result = await callRepository<List<ShiftModel>>(() => remoteDataSource.getShifts(loungeId: loungeId));
    return result.map((list) => list.cast<ShiftEntity>());
  }

  @override
  Future<Either<Failure, List<ShiftEntity>>> getShiftReport({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId,
  }) async {
    final result = await callRepository<List<ShiftModel>>(() => remoteDataSource.getShiftReport(
          loungeId: loungeId,
          startDate: startDate,
          endDate: endDate,
          cashierId: cashierId,
        ));
    return result.map((list) => list.cast<ShiftEntity>());
  }

  @override
  Future<Either<Failure, List<CashierPerformanceEntity>>> getCashierPerformance({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await callRepository<List<CashierPerformanceModel>>(() => remoteDataSource.getCashierPerformance(
          loungeId: loungeId,
          startDate: startDate,
          endDate: endDate,
        ));
    return result.map((list) => list.cast<CashierPerformanceEntity>());
  }

  @override
  Future<Either<Failure, List<LoungeComparisonEntity>>> getLoungeComparison({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await callRepository<List<LoungeComparisonModel>>(() => remoteDataSource.getLoungeComparison(
          startDate: startDate,
          endDate: endDate,
        ));
    return result.map((list) => list.cast<LoungeComparisonEntity>());
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
    final result = await callRepository<List<ShiftExpenseModel>>(() => remoteDataSource.fetchShiftExpenses(shiftId));
    return result.map((list) => list.cast<ShiftExpenseEntity>());
  }

  @override
  Future<Either<Failure, List<ShiftPaymentEntity>>> fetchShiftPayments(String shiftId) async {
    final result = await callRepository<List<ShiftPaymentModel>>(() => remoteDataSource.fetchShiftPayments(shiftId));
    return result.map((list) => list.cast<ShiftPaymentEntity>());
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchShiftBookings(String shiftId) async {
    return await callRepository<List<Map<String, dynamic>>>(() => remoteDataSource.fetchShiftBookings(shiftId));
  }

  @override
  Future<Either<Failure, List<ShiftAuditLogEntity>>> fetchShiftAuditLogs(String shiftId) async {
    final result = await callRepository<List<ShiftAuditLogModel>>(() => remoteDataSource.fetchShiftAuditLogs(shiftId));
    return result.map((list) => list.cast<ShiftAuditLogEntity>());
  }
}
