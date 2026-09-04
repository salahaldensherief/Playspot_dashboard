import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/analytics/domain/entities/lounge_stats_entity.dart';
import 'package:play_spot_dashboard/features/analytics/domain/repositories/dashboard_repository.dart';
import 'package:play_spot_dashboard/features/analytics/data/datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, LoungeStatsEntity>> getLoungeStats(String? loungeId) async {
    try {
      final stats = await remoteDataSource.fetchLoungeStats(loungeId);
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Booking>> watchActiveSessions({String? loungeId}) {
    return remoteDataSource.watchActiveSessions(loungeId: loungeId);
  }

  @override
  Future<Either<Failure, void>> extendSession(String bookingId, int additionalMinutes, {double? additionalCost}) async {
    try {
      await remoteDataSource.extendSession(bookingId, additionalMinutes, additionalCost: additionalCost);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addExtrasToSession(String bookingId, List<Map<String, dynamic>> extras, double additionalCost) async {
    try {
      await remoteDataSource.addExtrasToSession(bookingId, extras, additionalCost);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endSession(String bookingId) async {
    try {
      await remoteDataSource.endSession(bookingId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reviewExtensionRequest({
    required String bookingId,
    required bool isApproved,
    required int requestedMinutes,
    required int currentDurationMinutes,
  }) async {
    try {
      await remoteDataSource.reviewExtensionRequest(
        bookingId: bookingId,
        isApproved: isApproved,
        requestedMinutes: requestedMinutes,
        currentDurationMinutes: currentDurationMinutes,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> handleClientRequestAction({
    required String requestId,
    required bool isCanteenOrder,
    required bool approve,
    String? bookingId,
    int? extensionMinutes,
    List<Map<String, dynamic>>? extraItems,
    double? extraCost,
  }) async {
    try {
      await remoteDataSource.handleClientRequestAction(
        requestId: requestId,
        isCanteenOrder: isCanteenOrder,
        approve: approve,
        bookingId: bookingId,
        extensionMinutes: extensionMinutes,
        extraItems: extraItems,
        extraCost: extraCost,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
