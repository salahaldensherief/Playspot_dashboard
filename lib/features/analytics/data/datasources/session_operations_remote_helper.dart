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
    debugPrint(
      '🔵 [SessionOperationsRemoteHelper] Extending session: $bookingId by $additionalMinutes mins',
    );

    try {
      await supabaseClient.rpc(
        'extend_booking_session',
        params: {
          'p_booking_id': bookingId,
          'p_additional_minutes': additionalMinutes,
          'p_additional_cost': null,
        },
      );
      debugPrint(
        '🟢 [SessionOperationsRemoteHelper] Session extension RPC succeeded',
      );
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('BOOKING_EXTENSION_CONFLICT') ||
          errorStr.contains('23P01')) {
        throw Exception(
          'لا يمكن تمديد الحجز لأن هناك حجزاً آخر يبدأ بعد وقت حجزك مباشرة.',
        );
      }
      rethrow;
    }
  }
  Future<void> addExtrasToSession(
    String bookingId,
    List<Map<String, dynamic>> extras,
    double additionalCost,
  ) async {
    if (extras.isEmpty) return;

    final items = extras.map((extra) {
      final extraId = extra['extra_id'] ??
          extra['id'] ??
          extra['product_id'] ??
          extra['item_id'];
      final quantity = (extra['quantity'] as num?)?.toInt() ??
          (extra['qty'] as num?)?.toInt() ??
          1;

      return {
        'extra_id': extraId?.toString() ?? '',
        'quantity': quantity,
      };
    }).toList();

    await supabaseClient.rpc(
      'place_canteen_order',
      params: {
        'p_booking_id': bookingId,
        'p_items': items,
        'p_note': null,
      },
    );
  }
  Future<void> endSession(String bookingId) async {
    debugPrint('🔵 [SessionOperationsRemoteHelper] Ending session: $bookingId');

    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Authentication required');
    }

    await supabaseClient.rpc(
      'complete_booking_session',
      params: {
        'p_booking_id': bookingId,
        'p_action_by': userId,
      },
    );
  }

  Future<void> reviewExtensionRequest({
    required String bookingId,
    required bool isApproved,
    double? additionalCost,
    String? reason,
    int? requestedMinutes,
    int? currentDurationMinutes,
  }) async {
    final uuidRegExp = RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');
    final match = uuidRegExp.firstMatch(bookingId);
    final cleanBookingId = match != null ? match.group(0)! : bookingId.replaceAll('ext_', '').trim();

    if (!uuidRegExp.hasMatch(cleanBookingId)) {
      debugPrint('⚠️ [SESSION_OPERATIONS] Invalid booking UUID for extension request: $bookingId');
      return;
    }

    if (isApproved) {
      await supabaseClient.rpc('approve_booking_extension', params: {
        'p_booking_id': cleanBookingId,
        'p_additional_cost': null,
      });
    } else {
      await supabaseClient.rpc('reject_booking_extension', params: {
        'p_booking_id': cleanBookingId,
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
