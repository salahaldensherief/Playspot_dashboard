import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../domain/entities/shift_audit_log_entity.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/shift_expense_entity.dart';
import '../../domain/entities/shift_payment_entity.dart';
import '../../domain/repositories/shift_repository.dart';
import 'shift_state.dart';

class ShiftDetailsFetcher {
  final ShiftRepository repository;

  const ShiftDetailsFetcher(this.repository);

  Future<ShiftState> fetchDetails({
    required ShiftEntity shift,
    required ShiftState currentState,
  }) async {
    final results = await Future.wait([
      repository.fetchShiftExpenses(shift.id),
      repository.fetchShiftPayments(shift.id),
      repository.fetchShiftBookings(shift.id),
      repository.fetchShiftAuditLogs(shift.id),
    ]);

    final expensesRes = results[0] as Either<Failure, List<ShiftExpenseEntity>>;
    final paymentsRes = results[1] as Either<Failure, List<ShiftPaymentEntity>>;
    final bookingsRes = results[2] as Either<Failure, List<Map<String, dynamic>>>;
    final auditLogsRes = results[3] as Either<Failure, List<ShiftAuditLogEntity>>;

    return currentState.copyWith(
      selectedShiftDetails: shift,
      expenses: expensesRes.getOrElse(() => []),
      payments: paymentsRes.getOrElse(() => []),
      shiftBookings: bookingsRes.getOrElse(() => []),
      auditLogs: auditLogsRes.getOrElse(() => []),
    );
  }
}
