import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/payout_entity.dart';

abstract class PayoutRepository {
  Future<Either<Failure, List<PendingPayoutOverview>>> getPendingPayoutsOverview();
  Future<Either<Failure, Map<String, dynamic>>> createPayout({
    required String loungeId,
    required String periodStart,
    required String periodEnd,
  });
  Future<Either<Failure, void>> markPayoutPaid({
    required String payoutId,
    String? notes,
  });
  Future<Either<Failure, List<PayoutEntity>>> getPayoutsByLounge(String loungeId);
}
