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
    Timer? backupSyncTimer;
    Timer? debounceTimer;
    StreamSubscription? postgresSubscription;
    bool isFetching = false;

    void debouncedFetch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        if (isFetching || controller.isClosed) return;
        isFetching = true;
        try {
          await _fetchAndEmitActiveSessions(controller, cleanLoungeId);
        } finally {
          isFetching = false;
        }
      });
    }

    void cleanup() {
      debounceTimer?.cancel();
      backupSyncTimer?.cancel();
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
                debouncedFetch();
              }, onError: (e) {
                debugPrint('⚠️ [DASHBOARD_DATA_SOURCE] Active Sessions Realtime Error: $e');
              });
        } catch (e) {
          debugPrint('⚠️ [DASHBOARD_DATA_SOURCE] Active Sessions Stream Listener Exception: $e');
        }

        backupSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          debouncedFetch();
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
      if (loungeId != null && loungeId.isNotEmpty) {
        try {
          final rpcResponse = await supabaseClient.rpc(
            'get_live_bookings_with_items',
            params: {'p_lounge_id': loungeId},
          );
          if (rpcResponse != null && rpcResponse is List) {
            final list = rpcResponse
                .map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json)))
                .toList();
            if (!controller.isClosed) {
              controller.add(list);
              return;
            }
          }
        } catch (rpcErr) {
          debugPrint('⚠️ [DASHBOARD_DATA_SOURCE] get_live_bookings_with_items RPC error ($rpcErr), falling back to query');
        }
      }

      var query = supabaseClient.from('bookings').select('''
        *,
        canteen_orders (
          id,
          items,
          total_price,
          note,
          status,
          created_at,
          canteen_order_items (
            id,
            quantity,
            price,
            unit_price,
            total_price,
            extra_id,
            extras (id, name, name_ar, name_en, price, unit_price)
          )
        ),
        booking_items(id, name, quantity, price, total_price, status),
        profiles(full_name, phone, email),
        rooms(name, name_en, controllers_count, screen_size),
        lounges(name, location, location_point)
      ''');
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
    debugPrint('🔵 [DASHBOARD_DATA_SOURCE] Calling extend_booking_session RPC for booking $bookingId by $additionalMinutes mins');
    try {
      await supabaseClient.rpc('extend_booking_session', params: {
        'p_booking_id': bookingId,
        'p_additional_minutes': additionalMinutes,
      });
      debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Session extension RPC succeeded!');
    } catch (e) {
      final errorStr = e.toString();
      debugPrint('🔴 [DASHBOARD_DATA_SOURCE] extend_booking_session RPC error: $errorStr');

      if (errorStr.contains('BOOKING_EXTENSION_CONFLICT')) {
        throw Exception('لا يمكن تمديد الحجز لأن هناك حجزاً آخر يبدأ بعد وقت حجزك مباشرة.');
      }

      if (errorStr.contains('function') || errorStr.contains('parameter') || errorStr.contains('PGRST202')) {
        try {
          await supabaseClient.rpc('extend_booking_session', params: {
            'p_booking_id': bookingId,
            'p_minutes': additionalMinutes,
          });
          debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Session extension RPC succeeded with p_minutes!');
          return;
        } catch (e2) {
          final errorStr2 = e2.toString();
          if (errorStr2.contains('BOOKING_EXTENSION_CONFLICT')) {
            throw Exception('لا يمكن تمديد الحجز لأن هناك حجزاً آخر يبدأ بعد وقت حجزك مباشرة.');
          }
          try {
            await supabaseClient.rpc('extend_booking_session', params: {
              'p_booking_id': bookingId,
              'p_extension_minutes': additionalMinutes,
            });
            debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Session extension RPC succeeded with p_extension_minutes!');
            return;
          } catch (e3) {
            final errorStr3 = e3.toString();
            if (errorStr3.contains('BOOKING_EXTENSION_CONFLICT')) {
              throw Exception('لا يمكن تمديد الحجز لأن هناك حجزاً آخر يبدأ بعد وقت حجزك مباشرة.');
            }
            rethrow;
          }
        }
      }

      rethrow;
    }
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

        // 2. Place canteen order via RPC place_canteen_order (preferred) with direct insert fallback
        bool rpcSuccess = false;
        try {
          final rpcRes = await supabaseClient.rpc('place_canteen_order', params: {
            'p_booking_id': bookingId,
            'p_items': extras,
          });
          debugPrint('🟢 [CANTEEN_ORDER_SYNC] Successfully placed canteen order via RPC place_canteen_order: $rpcRes');
          rpcSuccess = true;
        } catch (rpcErr) {
          debugPrint('⚠️ [CANTEEN_ORDER_SYNC] place_canteen_order RPC failed ($rpcErr), falling back to direct insert');
        }

        if (!rpcSuccess && loungeId != null && loungeId.isNotEmpty) {
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
    double? additionalCost,
    String? reason,
    int? requestedMinutes,
    int? currentDurationMinutes,
  }) async {
    debugPrint('🔵 [DASHBOARD_DATA_SOURCE] reviewExtensionRequest: bookingId=$bookingId, isApproved=$isApproved, additionalCost=$additionalCost, reason=$reason');

    if (isApproved) {
      await supabaseClient.rpc('approve_booking_extension', params: {
        'p_booking_id': bookingId,
        'p_additional_cost': additionalCost ?? 0.0,
      });
      debugPrint('🟢 [DASHBOARD_DATA_SOURCE] RPC approve_booking_extension succeeded!');
    } else {
      await supabaseClient.rpc('reject_booking_extension', params: {
        'p_booking_id': bookingId,
        'p_reason': reason ?? 'لا يوجد وقت متاح بعد الحجز الحالي',
      });
      debugPrint('🟢 [DASHBOARD_DATA_SOURCE] RPC reject_booking_extension succeeded!');
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
    if (bookingId != null && bookingId.isNotEmpty) {
      if (approve) {
        if (extensionMinutes != null && extensionMinutes > 0) {
          await extendSession(bookingId, extensionMinutes, additionalCost: extraCost);
        }
        if (extraItems != null && extraItems.isNotEmpty) {
          await addExtrasToSession(bookingId, extraItems, extraCost ?? 0.0);
        }
      }
    }

    final String rawDbId = requestId
        .replaceFirst('canteen_', '')
        .replaceFirst('notif_', '')
        .replaceFirst('sc_', '')
        .replaceFirst('item_', '')
        .replaceFirst('req_', '')
        .replaceFirst('ext_', '');

    if (rawDbId.isEmpty) return;

    final tables = ['booking_items', 'canteen_orders', 'service_calls', 'client_requests', 'bookings', 'notifications'];
    final idCols = ['id', 'call_id', 'order_id', 'request_id', 'booking_id'];
    bool success = false;

    for (final table in tables) {
      for (final col in idCols) {
        try {
          Map<String, dynamic> updatePayload;
          if (table == 'bookings') {
            updatePayload = {'extension_status': approve ? 'approved' : 'rejected'};
          } else if (table == 'canteen_orders') {
            updatePayload = {'status': approve ? 'completed' : 'cancelled'};
          } else if (table == 'booking_items') {
            updatePayload = {'status': approve ? 'completed' : 'cancelled', 'is_attended': true, 'is_read': true};
          } else if (table == 'notifications') {
            updatePayload = {'is_read': true};
          } else {
            updatePayload ={'status': approve ? 'resolved' : 'rejected', 'is_attended': true, 'is_read': true};
          }

          final response = await supabaseClient
              .from(table)
              .update(updatePayload)
              .eq(col, rawDbId)
              .select();

          if ((response as List).isNotEmpty) {
            debugPrint('🟢 [DASHBOARD_DATA_SOURCE] Successfully updated request $requestId in table $table using column $col');
            success = true;
          }
        } catch (_) {}
      }
    }

    if (!success) {
      debugPrint('⚠️ [DASHBOARD_DATA_SOURCE] Warning: handleClientRequestAction update affected 0 rows for $requestId');
    }
  }
}
