import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/payout_entity.dart';

abstract class PayoutRepository {
  Future<Either<Failure, List<PendingPayoutOverview>>> getPendingPayoutsOverview();
  Future<Either<Failure, List<PayoutEntity>>> getAllPayouts();
  Future<Either<Failure, Map<String, dynamic>>> createPayout({
    required String loungeId,
    required String periodStart,
    required String periodEnd,
  });
  Future<Either<Failure, void>> approvePayout({
    required String payoutId,
    String? notes,
  });
  Future<Either<Failure, void>> startPayoutProcessing({
    required String payoutId,
  });
  Future<Either<Failure, void>> completePayout({
    required String payoutId,
    required String transferMethod,
    required String transferReference,
    String? receiptUrl,
    String? notes,
  });
  Future<Either<Failure, void>> markPayoutPaid({
    required String payoutId,
    String? notes,
  });
  Future<Either<Failure, void>> failPayout({
    required String payoutId,
    required String reason,
  });
  Future<Either<Failure, void>> cancelPayout({
    required String payoutId,
    required String reason,
  });
  Future<Either<Failure, void>> resolvePayoutReview({
    required String payoutId,
    required String resolution,
    required String reason,
  });
  Future<Either<Failure, Map<String, dynamic>>> getPayoutDetails({
    required String payoutId,
  });
  Future<Either<Failure, List<PayoutEntity>>> getPayoutsByLounge(String loungeId);
}
