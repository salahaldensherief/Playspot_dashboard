import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../domain/entities/payout_entity.dart';
import '../../domain/entities/payment_funds_review.dart';
import '../../domain/repositories/payout_repository.dart';
import '../datasources/payout_remote_data_source.dart';

class PayoutRepositoryImpl implements PayoutRepository {
  final PayoutRemoteDataSource remoteDataSource;

  PayoutRepositoryImpl(this.remoteDataSource);

  Failure _payoutFailure(Object error) {
    final message = error.toString();
    if (message.contains('PAYMENT_FUNDS_CUSTODY_REQUIRED')) {
      return ServerFailure(AppStrings.payoutCustodyRequired);
    }
    if (message.contains('PAYOUT_TRANSFER_EVIDENCE_REQUIRED')) {
      return ServerFailure(AppStrings.payoutTransferEvidenceRequired);
    }
    if (message.contains('RECONCILIATION') ||
        message.contains('PAYOUT_PAYMENT_EVIDENCE_CHANGED')) {
      return ServerFailure(AppStrings.payoutReconciliationRequired);
    }
    return ServerFailure(message);
  }

  @override
  Future<Either<Failure, List<PaymentFundsReview>>> getPaymentFundsReview({
    int offset = 0,
  }) async {
    try {
      return Right(
        await remoteDataSource.getPaymentFundsReview(offset: offset),
      );
    } catch (error) {
      return Left(_payoutFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> recordPaymentFundsCustody({
    required String paymentId,
    required PaymentFundsHolder holder,
    required String evidenceReference,
  }) async {
    try {
      await remoteDataSource.recordPaymentFundsCustody(
        paymentId: paymentId,
        holder: holder,
        evidenceReference: evidenceReference,
      );
      return const Right(null);
    } catch (error) {
      return Left(_payoutFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<PendingPayoutOverview>>>
  getPendingPayoutsOverview() async {
    try {
      final overviews = await remoteDataSource.getPendingPayoutsOverview();
      return Right(overviews);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<PayoutEntity>>> getAllPayouts({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final payouts = await remoteDataSource.getAllPayouts(
        page: page,
        pageSize: pageSize,
      );
      return Right(payouts);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createPayout({
    required String loungeId,
    required String periodStart,
    required String periodEnd,
  }) async {
    try {
      final result = await remoteDataSource.createPayout(
        loungeId: loungeId,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      if (result['success'] != true) {
        return Left(ServerFailure(AppStrings.payoutNoPositiveBalance));
      }
      return Right(result);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> approvePayout({
    required String payoutId,
    String? notes,
  }) async {
    try {
      await remoteDataSource.approvePayout(payoutId: payoutId, notes: notes);
      return const Right(null);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> startPayoutProcessing({
    required String payoutId,
  }) async {
    try {
      await remoteDataSource.startPayoutProcessing(payoutId: payoutId);
      return const Right(null);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> completePayout({
    required String payoutId,
    required String transferMethod,
    required String transferReference,
    String? receiptUrl,
    String? notes,
  }) async {
    try {
      await remoteDataSource.completePayout(
        payoutId: payoutId,
        transferMethod: transferMethod,
        transferReference: transferReference,
        receiptUrl: receiptUrl,
        notes: notes,
      );
      return const Right(null);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> markPayoutPaid({
    required String payoutId,
    String? notes,
  }) async {
    try {
      await remoteDataSource.markPayoutPaid(payoutId: payoutId, notes: notes);
      return const Right(null);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> failPayout({
    required String payoutId,
    required String reason,
  }) async {
    try {
      await remoteDataSource.failPayout(payoutId: payoutId, reason: reason);
      return const Right(null);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> cancelPayout({
    required String payoutId,
    required String reason,
  }) async {
    try {
      await remoteDataSource.cancelPayout(payoutId: payoutId, reason: reason);
      return const Right(null);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> resolvePayoutReview({
    required String payoutId,
    required String resolution,
    required String reason,
  }) async {
    try {
      await remoteDataSource.resolvePayoutReview(
        payoutId: payoutId,
        resolution: resolution,
        reason: reason,
      );
      return const Right(null);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPayoutDetails({
    required String payoutId,
  }) async {
    try {
      final details = await remoteDataSource.getPayoutDetails(
        payoutId: payoutId,
      );
      return Right(details);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<PayoutEntity>>> getPayoutsByLounge(
    String loungeId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final payouts = await remoteDataSource.getPayoutsByLounge(
        loungeId,
        page: page,
        pageSize: pageSize,
      );
      return Right(payouts);
    } catch (e) {
      return Left(_payoutFailure(e));
    }
  }
}
