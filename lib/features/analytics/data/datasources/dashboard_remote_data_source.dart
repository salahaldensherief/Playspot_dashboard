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
    debugPrint('====================================================');
    debugPrint('🚀 [CANTEEN_ORDER_SYNC] Executing addExtrasToSession...');
    debugPrint('📌 [CANTEEN_ORDER_SYNC] Booking ID: $bookingId');
    debugPrint('💰 [CANTEEN_ORDER_SYNC] Additional Cost: $additionalCost');
    debugPrint('📦 [CANTEEN_ORDER_SYNC] Incoming Extras Payload (${extras.length} items):');
    for (int i = 0; i < extras.length; i++) {
      debugPrint('   - Item [$i]: ${extras[i]}');
    }
    debugPrint('====================================================');

    try {
      if (extras.isNotEmpty) {
        // 1. Fetch lounge_id, user_id, total_price, & addons_price for the booking
        final bookingDetails = await supabaseClient
            .from('bookings')
            .select('lounge_id, user_id, total_price, addons_price')
            .eq('id', bookingId)
            .maybeSingle();

        final loungeId = bookingDetails?['lounge_id']?.toString();
        final userId = bookingDetails?['user_id']?.toString();
        final currentTotalPrice = (bookingDetails?['total_price'] as num?)?.toDouble() ?? 0.0;
        final currentAddonsPrice = (bookingDetails?['addons_price'] as num?)?.toDouble() ?? 0.0;

        // 2. Insert into canteen_orders table
        if (loungeId != null && loungeId.isNotEmpty) {
          try {
            await supabaseClient.from('canteen_orders').insert({
              'lounge_id': loungeId,
              'booking_id': bookingId,
              if (userId != null && userId.isNotEmpty) 'user_id': userId,
              'items': extras,
              'total_price': additionalCost,
              'status': 'completed',
            });
            debugPrint('🟢 [CANTEEN_ORDER_SYNC] Successfully inserted into `canteen_orders`!');
          } catch (e) {
            debugPrint('⚠️ [CANTEEN_ORDER_SYNC] canteen_orders insert warning: $e');
            try {
              await supabaseClient.from('canteen_orders').insert({
                'lounge_id': loungeId,
                'booking_id': bookingId,
                'items': extras,
                'total_price': additionalCost,
              });
            } catch (_) {}
          }
        }

        // 3. Update bookings table (total_price & addons_price)
        final updatedTotalPrice = currentTotalPrice + additionalCost;
        final updatedAddonsPrice = currentAddonsPrice + additionalCost;

        debugPrint('🔵 [CANTEEN_ORDER_SYNC] Updating `total_price` ($updatedTotalPrice) and `addons_price` ($updatedAddonsPrice) on `bookings`...');
        try {
          await supabaseClient.from('bookings').update({
            'total_price': updatedTotalPrice,
            'addons_price': updatedAddonsPrice,
          }).eq('id', bookingId);
        } catch (_) {
          try {
            await supabaseClient.from('bookings').update({
              'total_price': updatedTotalPrice,
            }).eq('id', bookingId);
          } catch (_) {}
        }

        // 4. Failsafe optional insert to booking_items table
        try {
          final List<Map<String, dynamic>> bookingItemsToInsert = extras.map((e) {
            final qty = (e['quantity'] as num?)?.toInt() ?? 1;
            final price = (e['price'] ?? e['unit_price'] as num?)?.toDouble() ?? 0.0;
            return {
              'booking_id': bookingId,
              'name': e['name'] ?? e['name_ar'] ?? e['item_name'] ?? 'Extra Item',
              'quantity': qty,
              'price': price,
              'total_price': price * qty,
            };
          }).toList();
          await supabaseClient.from('booking_items').insert(bookingItemsToInsert);
        } catch (e) {
          debugPrint('ℹ️ [CANTEEN_ORDER_SYNC] booking_items optional insert skipped: $e');
        }
      }

      debugPrint('🟢 [CANTEEN_ORDER_SYNC] Successfully added extras to session!');
      debugPrint('====================================================');
    } catch (e) {
      debugPrint('🔴 [CANTEEN_ORDER_SYNC] Error in addExtrasToSession: $e');
      debugPrint('====================================================');
      rethrow;
    }
  }

  @override
  Future<void> endSession(String bookingId) async {
    debugPrint('🔵 [DASHBOARD_DATA_SOURCE] Ending active session: $bookingId');
    final userId = supabaseClient.auth.currentUser?.id;
    try {
      await supabaseClient.rpc('complete_booking_session', params: {
        'p_booking_id': bookingId,
        'p_action_by': userId ?? '',
      });
      debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Session ended via RPC complete_booking_session!');
    } catch (e) {
      debugPrint('⚠️ [DASHBOARD_DATA_SOURCE] RPC complete_booking_session failed ($e), falling back to update_booking_status_admin...');
      try {
        await supabaseClient.rpc('update_booking_status_admin', params: {
          'p_booking_id': bookingId,
          'p_status': 'completed',
        });
        debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Session ended via update_booking_status_admin!');
      } catch (_) {
        await supabaseClient
            .from('bookings')
            .update({'status': 'completed'})
            .eq('id', bookingId);
        debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Direct update endSession completed!');
      }
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

      if (requestId.startsWith('sc_')) {
        final scId = requestId.replaceFirst('sc_', '');
        try {
          await supabaseClient
              .from('service_calls')
              .update({'status': approve ? 'resolved' : 'rejected', 'is_attended': true, 'is_read': true})
              .eq('id', scId);
        } catch (_) {
          await supabaseClient
              .from('service_calls')
              .update({'status': approve ? 'resolved' : 'rejected'})
              .eq('id', scId);
        }
      } else if (isCanteenOrder) {
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
      if (requestId.startsWith('sc_')) {
        final scId = requestId.replaceFirst('sc_', '');
        try {
          await supabaseClient
              .from('service_calls')
              .update({'status': 'rejected', 'is_attended': true, 'is_read': true})
              .eq('id', scId);
        } catch (_) {
          await supabaseClient
              .from('service_calls')
              .update({'status': 'rejected'})
              .eq('id', scId);
        }
      } else if (isCanteenOrder) {
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
