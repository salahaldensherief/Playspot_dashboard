import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/lounges/data/datasources/lounge_remote_data_source.dart';

class LoungeAnalyticsRepositoryHelper {
  final LoungeRemoteDataSource remoteDataSource;

  LoungeAnalyticsRepositoryHelper(this.remoteDataSource);

  Future<Either<Failure, Map<String, dynamic>>> getDashboardStats(String? loungeId) async {
    try {
      final stats = await remoteDataSource.getDashboardStats(loungeId);
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getDashboardOverview() async {
    try {
      final overview = await remoteDataSource.getDashboardOverview();
      return Right(overview);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getRevenueOverTime(int daysBack) async {
    try {
      final chart = await remoteDataSource.getRevenueOverTime(daysBack);
      return Right(chart);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getTopLoungesByRevenue(int limitCount) async {
    try {
      final top = await remoteDataSource.getTopLoungesByRevenue(limitCount);
      return Right(top);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
