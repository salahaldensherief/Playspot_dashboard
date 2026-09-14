import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/shift_entity.dart';
import '../entities/live_shift_overview_entity.dart';
import '../entities/shift_expense_entity.dart';
import '../entities/shift_payment_entity.dart';
import '../entities/cashier_performance_entity.dart';
import '../entities/lounge_comparison_entity.dart';
import '../entities/shift_audit_log_entity.dart';

abstract class ShiftRepository {
  Future<Either<Failure, ShiftEntity?>> getActiveShift(String loungeId);
  Future<Either<Failure, LiveShiftOverviewEntity>> getLoungeLiveShiftOverview(String loungeId);
  Future<Either<Failure, void>> openShift(String loungeId, double startingCash, {String? notes});
  Future<Either<Failure, void>> quickOpenShift(String loungeId, [double startingCash = 0.0, String? notes]);
  Future<Either<Failure, ShiftEntity>> closeShift(String shiftId, double actualCash, String? notes, {String? loungeId});
  Future<Either<Failure, List<ShiftEntity>>> getShiftHistory({String? loungeId});
  Future<Either<Failure, List<ShiftEntity>>> getShiftReport({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId,
  });
  Future<Either<Failure, List<CashierPerformanceEntity>>> getCashierPerformance({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, List<LoungeComparisonEntity>>> getLoungeComparison({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, void>> approveShift(String shiftId, String managerId, String? notes);
  Future<Either<Failure, void>> addShiftExpense(ShiftExpenseEntity expense);
  Future<Either<Failure, List<ShiftExpenseEntity>>> fetchShiftExpenses(String shiftId);
  Future<Either<Failure, List<ShiftPaymentEntity>>> fetchShiftPayments(String shiftId);
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchShiftBookings(String shiftId);
  Future<Either<Failure, List<ShiftAuditLogEntity>>> fetchShiftAuditLogs(String shiftId);
}
