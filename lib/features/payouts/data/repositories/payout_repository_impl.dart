import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../domain/entities/payout_entity.dart';
import '../../domain/repositories/payout_repository.dart';
import '../datasources/payout_remote_data_source.dart';

class PayoutRepositoryImpl implements PayoutRepository {
  final PayoutRemoteDataSource remoteDataSource;

  PayoutRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<PendingPayoutOverview>>> getPendingPayoutsOverview() async {
    try {
      final overviews = await remoteDataSource.getPendingPayoutsOverview();
      return Right(overviews);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markPayoutPaid({
    required String payoutId,
    String? notes,
  }) async {
    try {
      await remoteDataSource.markPayoutPaid(
        payoutId: payoutId,
        notes: notes,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PayoutEntity>>> getPayoutsByLounge(String loungeId) async {
    try {
      final payouts = await remoteDataSource.getPayoutsByLounge(loungeId);
      return Right(payouts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
