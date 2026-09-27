import '../models/cashier_performance_model.dart';
import '../models/live_shift_overview_model.dart';
import '../models/lounge_comparison_model.dart';
import '../models/shift_audit_log_model.dart';
import '../models/shift_expense_model.dart';
import '../models/shift_model.dart';
import '../models/shift_payment_model.dart';

abstract class ShiftRemoteDataSource {
  Future<List<ShiftModel>> getShifts({String? loungeId, int limit = 50, int offset = 0});
  Future<List<ShiftModel>> getShiftReport({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId,
  });
  Future<List<CashierPerformanceModel>> getCashierPerformance({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<LoungeComparisonModel>> getLoungeComparison({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<ShiftModel?> getActiveShift(String loungeId);
  Future<LiveShiftOverviewModel> getLoungeLiveShiftOverview(String loungeId);
  Future<void> openShift(String loungeId, double startingCash, {String? notes});
  Future<ShiftModel> closeShift(String shiftId, double actualCash, String? notes, {String? loungeId});
  Future<void> approveShift(String shiftId, String managerId, String? notes);
  Future<void> addShiftExpense(ShiftExpenseModel expense);
  Future<List<ShiftExpenseModel>> fetchShiftExpenses(String shiftId);
  Future<List<ShiftPaymentModel>> fetchShiftPayments(String shiftId);
  Future<List<Map<String, dynamic>>> fetchShiftBookings(String shiftId);
  Future<List<ShiftAuditLogModel>> fetchShiftAuditLogs(String shiftId);
}
