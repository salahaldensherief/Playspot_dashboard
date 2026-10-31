import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cashier_conflict.dart';

abstract class CashierConflictRepository {
  Future<Either<Failure, List<CashierConflict>>> load(
    String actorId,
    String loungeId,
  );
  Future<Either<Failure, void>> approve({
    required String actorId,
    required String loungeId,
    required String operationId,
    required String reviewId,
    required String reason,
  });
}
