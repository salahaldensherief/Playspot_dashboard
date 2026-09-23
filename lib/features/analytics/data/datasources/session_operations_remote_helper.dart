import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionOperationsRemoteHelper {
  final SupabaseClient supabaseClient;

  SessionOperationsRemoteHelper(this.supabaseClient);

  Future<void> extendSession(
    String bookingId,
    int additionalMinutes, {
    double? additionalCost,
  }) async {
    debugPrint('🔵 [SessionOperationsRemoteHelper] Extending session: $bookingId by $additionalMinutes mins');
    try {
      await supabaseClient.rpc('extend_booking_session', params: {
        'p_booking_id': bookingId,
        'p_additional_minutes': additionalMinutes,
      });
      debugPrint('🟢 [SessionOperationsRemoteHelper] Session extension RPC succeeded!');
    } catch (e) {
      final errorStr = e.toString();
      debugPrint('🔴 [SessionOperationsRemoteHelper] extend_booking_session RPC error: $errorStr');

      if (errorStr.contains('BOOKING_EXTENSION_CONFLICT')) {
        throw Exception('لا يمكن تمديد الحجز لأن هناك حجزاً آخر يبدأ بعد وقت حجزك مباشرة.');
      }

      if (errorStr.contains('function') ||
          errorStr.contains('parameter') ||
          errorStr.contains('PGRST202')) {
        try {
          await supabaseClient.rpc('extend_booking_session', params: {
            'p_booking_id': bookingId,
            'p_minutes': additionalMinutes,
          });
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

  Future<void> addExtrasToSession(
    String bookingId,
    List<Map<String, dynamic>> extras,
    double additionalCost,
  ) async {
    try {
      if (extras.isNotEmpty) {
        final bookingDetails = await supabaseClient
            .from('bookings')
            .select('lounge_id, user_id, total_price, addons_price')
            .eq('id', bookingId)
            .maybeSingle();

        final loungeId = bookingDetails?['lounge_id']?.toString();
        final userId = bookingDetails?['user_id']?.toString();
        final currentTotalPrice = (bookingDetails?['total_price'] as num?)?.toDouble() ?? 0.0;
        final currentAddonsPrice = (bookingDetails?['addons_price'] as num?)?.toDouble() ?? 0.0;

        bool rpcSuccess = false;
        try {
          await supabaseClient.rpc('place_canteen_order', params: {
            'p_booking_id': bookingId,
            'p_items': extras,
          });
          rpcSuccess = true;
        } catch (rpcErr) {
          debugPrint('⚠️ [SessionOperationsRemoteHelper] place_canteen_order fallback: $rpcErr');
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
          } catch (_) {
            try {
              await supabaseClient.from('canteen_orders').insert({
                'lounge_id': loungeId,
                'booking_id': bookingId,
                'items': extras,
                'total_price': additionalCost,
              });
            } catch (_) {}
          }

          final updatedTotalPrice = currentTotalPrice + additionalCost;
          final updatedAddonsPrice = currentAddonsPrice + additionalCost;

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
        }

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
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('🔴 [SessionOperationsRemoteHelper] Error in addExtrasToSession: $e');
      rethrow;
    }
  }

  Future<void> endSession(String bookingId) async {
    debugPrint('🔵 [SessionOperationsRemoteHelper] Ending session: $bookingId');
    final userId = supabaseClient.auth.currentUser?.id;
    try {
      await supabaseClient.rpc('complete_booking_session', params: {
        'p_booking_id': bookingId,
        'p_action_by': userId ?? '',
      });
    } catch (e) {
      try {
        await supabaseClient.rpc('update_booking_status_admin', params: {
          'p_booking_id': bookingId,
          'p_status': 'completed',
        });
      } catch (_) {
        await supabaseClient
            .from('bookings')
            .update({'status': 'completed'})
            .eq('id', bookingId);
      }
    }
  }

  Future<void> reviewExtensionRequest({
    required String bookingId,
    required bool isApproved,
    double? additionalCost,
    String? reason,
    int? requestedMinutes,
    int? currentDurationMinutes,
  }) async {
    if (isApproved) {
      await supabaseClient.rpc('approve_booking_extension', params: {
        'p_booking_id': bookingId,
        'p_additional_cost': additionalCost ?? 0.0,
      });
    } else {
      await supabaseClient.rpc('reject_booking_extension', params: {
        'p_booking_id': bookingId,
        'p_reason': reason ?? 'لا يوجد وقت متاح بعد الحجز الحالي',
      });
    }
  }

  Future<void> handleClientRequestAction({
    required String requestId,
    required bool isCanteenOrder,
    required bool approve,
    String? bookingId,
    int? extensionMinutes,
    List<Map<String, dynamic>>? extraItems,
    double? extraCost,
  }) async {
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

    final tables = [
      'booking_items',
      'canteen_orders',
      'service_calls',
      'client_requests',
      'bookings',
      'notifications'
    ];
    final idCols = ['id', 'call_id', 'order_id', 'request_id', 'booking_id'];

    for (final table in tables) {
      for (final col in idCols) {
        try {
          Map<String, dynamic> updatePayload;
          if (table == 'bookings') {
            updatePayload = {'extension_status': approve ? 'approved' : 'rejected'};
          } else if (table == 'canteen_orders') {
            updatePayload = {'status': approve ? 'completed' : 'cancelled'};
          } else if (table == 'booking_items') {
            updatePayload = {
              'status': approve ? 'completed' : 'cancelled',
              'is_attended': true,
              'is_read': true
            };
          } else if (table == 'notifications') {
            updatePayload = {'is_read': true};
          } else {
            updatePayload = {
              'status': approve ? 'resolved' : 'rejected',
              'is_attended': true,
              'is_read': true
            };
          }

          final response = await supabaseClient
              .from(table)
              .update(updatePayload)
              .eq(col, rawDbId)
              .select();

          if ((response as List).isNotEmpty) {
            return;
          }
        } catch (_) {}
      }
    }
  }
}
