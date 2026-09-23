import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';

class ActiveSessionsStreamHelper {
  final SupabaseClient supabaseClient;

  ActiveSessionsStreamHelper(this.supabaseClient);

  Stream<List<BookingModel>> watchActiveSessions({String? loungeId}) {
    final cleanLoungeId =
        (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;
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
                debugPrint('⚠️ [ActiveSessionsStreamHelper] Realtime Error: $e');
              });
        } catch (e) {
          debugPrint('⚠️ [ActiveSessionsStreamHelper] Stream Listener Exception: $e');
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
          debugPrint(
            '⚠️ [ActiveSessionsStreamHelper] get_live_bookings_with_items RPC error ($rpcErr)',
          );
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
          debugPrint('🔴 [ActiveSessionsStreamHelper] Fallback Error: $e2');
          controller.addError(e2);
        }
      }
    }
  }
}
