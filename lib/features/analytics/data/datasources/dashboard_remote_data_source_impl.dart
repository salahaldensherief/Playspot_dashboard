import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';
import 'package:play_spot_dashboard/features/analytics/data/models/lounge_stats_model.dart';
import 'active_sessions_stream_helper.dart';
import 'dashboard_remote_data_source.dart';
import 'session_operations_remote_helper.dart';

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final SupabaseClient supabaseClient;
  late final ActiveSessionsStreamHelper _streamHelper;
  late final SessionOperationsRemoteHelper _operationsHelper;

  DashboardRemoteDataSourceImpl(this.supabaseClient) {
    _streamHelper = ActiveSessionsStreamHelper(supabaseClient);
    _operationsHelper = SessionOperationsRemoteHelper(supabaseClient);
  }

  @override
  Future<LoungeStatsModel> fetchLoungeStats(String? loungeId) async {
    if (loungeId == null || loungeId.isEmpty) {
      throw Exception('Lounge ID is required');
    }

    final response = await supabaseClient.rpc(
      'get_lounge_owner_dashboard_stats',
      params: {
        'p_lounge_id': loungeId,
      },
    );

    if (response == null) {
      throw Exception('No data received');
    }

    return LoungeStatsModel.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Stream<List<BookingModel>> watchActiveSessions({String? loungeId}) =>
      _streamHelper.watchActiveSessions(loungeId: loungeId);

  @override
  Future<void> extendSession(
    String bookingId,
    int additionalMinutes, {
    double? additionalCost,
  }) =>
      _operationsHelper.extendSession(
        bookingId,
        additionalMinutes,
        additionalCost: additionalCost,
      );

  @override
  Future<void> addExtrasToSession(
    String bookingId,
    List<Map<String, dynamic>> extras,
    double additionalCost,
  ) =>
      _operationsHelper.addExtrasToSession(bookingId, extras, additionalCost);

  @override
  Future<void> endSession(String bookingId) =>
      _operationsHelper.endSession(bookingId);

  @override
  Future<void> reviewExtensionRequest({
    required String bookingId,
    required bool isApproved,
    double? additionalCost,
    String? reason,
    int? requestedMinutes,
    int? currentDurationMinutes,
  }) =>
      _operationsHelper.reviewExtensionRequest(
        bookingId: bookingId,
        isApproved: isApproved,
        additionalCost: additionalCost,
        reason: reason,
        requestedMinutes: requestedMinutes,
        currentDurationMinutes: currentDurationMinutes,
      );

  @override
  Future<void> handleClientRequestAction({
    required String requestId,
    required bool isCanteenOrder,
    required bool approve,
    String? bookingId,
    int? extensionMinutes,
    List<Map<String, dynamic>>? extraItems,
    double? extraCost,
  }) =>
      _operationsHelper.handleClientRequestAction(
        requestId: requestId,
        isCanteenOrder: isCanteenOrder,
        approve: approve,
        bookingId: bookingId,
        extensionMinutes: extensionMinutes,
        extraItems: extraItems,
        extraCost: extraCost,
      );
}
