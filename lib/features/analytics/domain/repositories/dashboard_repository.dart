import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/analytics/domain/entities/lounge_stats_entity.dart';

abstract class DashboardRepository {
  Future<Either<Failure, LoungeStatsEntity>> getLoungeStats(String? loungeId);
  Stream<List<Booking>> watchActiveSessions({String? loungeId});
  Future<Either<Failure, void>> extendSession(String bookingId, int additionalMinutes, {double? additionalCost});
  Future<Either<Failure, void>> addExtrasToSession(String bookingId, List<Map<String, dynamic>> extras, double additionalCost);
  Future<Either<Failure, void>> endSession(String bookingId);
  Future<Either<Failure, void>> reviewExtensionRequest({
    required String bookingId,
    required bool isApproved,
    required int requestedMinutes,
    required int currentDurationMinutes,
  });
  Future<Either<Failure, void>> handleClientRequestAction({
    required String requestId,
    required bool isCanteenOrder,
    required bool approve,
    String? bookingId,
    int? extensionMinutes,
    List<Map<String, dynamic>>? extraItems,
    double? extraCost,
  });
}
