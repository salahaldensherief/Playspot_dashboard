import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/shift_entity.dart';
import '../entities/live_shift_overview_entity.dart';
import '../entities/shift_expense_entity.dart';

abstract class ShiftRepository {
  Future<Either<Failure, ShiftEntity?>> getActiveShift(String loungeId);
  Future<Either<Failure, LiveShiftOverviewEntity>> getLoungeLiveShiftOverview(String loungeId);
  Future<Either<Failure, void>> openShift(String loungeId, double startingCash);
  Future<Either<Failure, ShiftEntity>> closeShift(String shiftId, double actualCash, String? notes);
  Future<Either<Failure, List<ShiftEntity>>> getShiftHistory({String? loungeId});
  Future<Either<Failure, void>> approveShift(String shiftId, String managerId, String? notes);
  Future<Either<Failure, void>> addShiftExpense(ShiftExpenseEntity expense);
  Future<Either<Failure, List<ShiftExpenseEntity>>> fetchShiftExpenses(String shiftId);
}
