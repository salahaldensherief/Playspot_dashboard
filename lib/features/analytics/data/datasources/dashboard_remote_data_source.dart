import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';
import 'package:play_spot_dashboard/features/analytics/data/models/lounge_stats_model.dart';

abstract class DashboardRemoteDataSource {
  Future<LoungeStatsModel> fetchLoungeStats(String? loungeId);
  Stream<List<BookingModel>> watchActiveSessions({String? loungeId});
  Future<void> extendSession(String bookingId, int additionalMinutes, {double? additionalCost});
  Future<void> addExtrasToSession(String bookingId, List<Map<String, dynamic>> extras, double additionalCost);
  Future<void> endSession(String bookingId);
  Future<void> reviewExtensionRequest({
    required String bookingId,
    required bool isApproved,
    double? additionalCost,
    String? reason,
    int? requestedMinutes,
    int? currentDurationMinutes,
  });
  Future<void> handleClientRequestAction({
    required String requestId,
    required bool isCanteenOrder,
    required bool approve,
    String? bookingId,
    int? extensionMinutes,
    List<Map<String, dynamic>>? extraItems,
    double? extraCost,
  });
}
