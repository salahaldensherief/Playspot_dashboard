import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    required int requestedMinutes,
    required int currentDurationMinutes,
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

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final SupabaseClient supabaseClient;

  DashboardRemoteDataSourceImpl(this.supabaseClient);

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
  Stream<List<BookingModel>> watchActiveSessions({String? loungeId}) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;
    late StreamController<List<BookingModel>> controller;
    Timer? heartbeatTimer;
    StreamSubscription? postgresSubscription;

    void cleanup() {
      heartbeatTimer?.cancel();
      postgresSubscription?.cancel();
    }

    controller = StreamController<List<BookingModel>>(
      onListen: () {
        _fetchAndEmitActiveSessions(controller, cleanLoungeId);

        try {
          postgresSubscription = supabaseClient
              .from('bookings')
              .stream(primaryKey: ['id'])
              .listen((_) {
                _fetchAndEmitActiveSessions(controller, cleanLoungeId);
              }, onError: (e) {
                debugPrint('⚠️ [DASHBOARD_DATA_SOURCE] Active Sessions Realtime Error: $e');
              });
        } catch (e) {
          debugPrint('⚠️ [DASHBOARD_DATA_SOURCE] Active Sessions Stream Listener Exception: $e');
        }

        heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          _fetchAndEmitActiveSessions(controller, cleanLoungeId);
        });
      },
      onCancel: cleanup,
    );

    return controller.stream;
  }

  Future<void> _fetchAndEmitActiveSessions(
    StreamController<List<BookingModel>> controller,
    String? loungeId,
  ) async {
    try {
      var query = supabaseClient.from('bookings').select('*, profiles(full_name, phone, email), rooms(name, name_en)');
      if (loungeId != null && loungeId.isNotEmpty) {
        query = query.eq('lounge_id', loungeId);
      }
      final response = await query
          .eq('status', 'in_progress')
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      if (!controller.isClosed) {
        controller.add(list);
      }
    } catch (e) {
      if (!controller.isClosed) {
        try {
          var query = supabaseClient.from('bookings').select();
          if (loungeId != null && loungeId.isNotEmpty) {
            query = query.eq('lounge_id', loungeId);
          }
          final response = await query
              .eq('status', 'in_progress')
              .order('created_at', ascending: false);
          final list = (response as List)
              .map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          controller.add(list);
        } catch (e2) {
          debugPrint('🔴 [DASHBOARD_DATA_SOURCE] _fetchAndEmitActiveSessions Fallback Error: $e2');
          controller.addError(e2);
        }
      }
    }
  }

  @override
  Future<void> extendSession(String bookingId, int additionalMinutes, {double? additionalCost}) async {
    final response = await supabaseClient
        .from('bookings')
        .select('duration_minutes, total_price')
        .eq('id', bookingId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Booking not found: $bookingId');
    }

    final currentMinutes = (response['duration_minutes'] as num?)?.toInt() ?? 60;
    final currentPrice = (response['total_price'] as num?)?.toDouble() ?? 0.0;

    final newMinutes = currentMinutes + additionalMinutes;
    double addedCost = additionalCost ?? 0.0;
    if (addedCost <= 0.0 && currentMinutes > 0) {
      final pricePerMinute = currentPrice / currentMinutes;
      addedCost = pricePerMinute * additionalMinutes;
    }

    final newTotalPrice = currentPrice + addedCost;

    debugPrint('🔵 [DASHBOARD_DATA_SOURCE] Extending booking $bookingId by $additionalMinutes mins to $newMinutes mins, new price: $newTotalPrice');

    await supabaseClient.from('bookings').update({
      'duration_minutes': newMinutes,
      'total_price': newTotalPrice,
    }).eq('id', bookingId);

    debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Session extension saved successfully!');
  }

  @override
  Future<void> addExtrasToSession(String bookingId, List<Map<String, dynamic>> extras, double additionalCost) async {
    final response = await supabaseClient
        .from('bookings')
        .select('extras, total_price')
        .eq('id', bookingId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Booking not found: $bookingId');
    }

    final List<Map<String, dynamic>> existingExtras = List<Map<String, dynamic>>.from(
      response['extras'] ?? response['booking_extras'] ?? [],
    );

    final currentTotalPrice = (response['total_price'] as num?)?.toDouble() ?? 0.0;
    final updatedExtras = [...existingExtras, ...extras];
    final updatedTotalPrice = currentTotalPrice + additionalCost;

    debugPrint('🔵 [DASHBOARD_DATA_SOURCE] Adding ${extras.length} extra items to booking $bookingId, new total: $updatedTotalPrice');

    await supabaseClient.from('bookings').update({
      'extras': updatedExtras,
      'total_price': updatedTotalPrice,
    }).eq('id', bookingId);

    debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Extras added to session successfully!');
  }

  @override
  Future<void> endSession(String bookingId) async {
    debugPrint('🔵 [DASHBOARD_DATA_SOURCE] Ending active session: $bookingId');
    try {
      await supabaseClient.rpc('update_booking_status_admin', params: {
        'p_booking_id': bookingId,
        'p_status': 'completed',
      });
      debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Session ended via RPC!');
    } catch (e) {
      debugPrint('⚠️ [DASHBOARD_DATA_SOURCE] RPC endSession failed ($e), attempting direct update fallback...');
      await supabaseClient
          .from('bookings')
          .update({'status': 'completed'})
          .eq('id', bookingId);
      debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Direct update endSession completed!');
    }
  }

  @override
  Future<void> reviewExtensionRequest({
    required String bookingId,
    required bool isApproved,
    required int requestedMinutes,
    required int currentDurationMinutes,
  }) async {
    debugPrint('🔵 [DASHBOARD_DATA_SOURCE] reviewExtensionRequest: bookingId=$bookingId, isApproved=$isApproved, requestedMinutes=$requestedMinutes, currentDurationMinutes=$currentDurationMinutes');

    if (isApproved) {
      final newDuration = currentDurationMinutes + requestedMinutes;
      await supabaseClient.from('bookings').update({
        'duration_minutes': newDuration,
        'extension_status': 'approved',
      }).eq('id', bookingId);
      debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Extension request approved: duration updated to $newDuration mins');
    } else {
      await supabaseClient.from('bookings').update({
        'extension_status': 'rejected',
      }).eq('id', bookingId);
      debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Extension request rejected');
    }
  }

  @override
  Future<void> handleClientRequestAction({
    required String requestId,
    required bool isCanteenOrder,
    required bool approve,
    String? bookingId,
    int? extensionMinutes,
    List<Map<String, dynamic>>? extraItems,
    double? extraCost,
  }) async {
    debugPrint('🔵 [DASHBOARD_DATA_SOURCE] handleClientRequestAction: id=$requestId, approve=$approve, bookingId=$bookingId');
    if (approve) {
      if (bookingId != null && bookingId.isNotEmpty) {
        if (extensionMinutes != null && extensionMinutes > 0) {
          await extendSession(bookingId, extensionMinutes, additionalCost: extraCost);
        }
        if (extraItems != null && extraItems.isNotEmpty) {
          await addExtrasToSession(bookingId, extraItems, extraCost ?? 0.0);
        }
      }

      if (isCanteenOrder) {
        await supabaseClient
            .from('canteen_orders')
            .update({'status': 'completed', 'is_attended': true})
            .eq('id', requestId);
      } else {
        await supabaseClient
            .from('notifications')
            .update({'is_read': true, 'is_attended': true})
            .eq('id', requestId);
      }
      debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Client request approved and session updated');
    } else {
      if (isCanteenOrder) {
        await supabaseClient
            .from('canteen_orders')
            .update({'status': 'rejected', 'is_attended': true})
            .eq('id', requestId);
      } else {
        await supabaseClient
            .from('notifications')
            .update({'is_read': true, 'is_attended': true})
            .eq('id', requestId);
      }
      debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Client request rejected');
    }
  }
}
