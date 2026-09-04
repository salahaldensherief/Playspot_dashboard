import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_request_model.dart';

abstract class RequestsRemoteDataSource {
  /// Stream combined real-time notifications, canteen orders, and pending extensions for a lounge.
  Stream<List<ClientRequestModel>> watchClientRequests({required String loungeId});

  /// Fetch combined client requests once for a lounge.
  Future<List<ClientRequestModel>> getClientRequests({required String loungeId});

  /// Mark notification or canteen order as attended / read.
  Future<void> markRequestAsAttended(String id, {bool isCanteenOrder = false});
}

class RequestsRemoteDataSourceImpl implements RequestsRemoteDataSource {
  final SupabaseClient client;

  RequestsRemoteDataSourceImpl(this.client);

  @override
  Stream<List<ClientRequestModel>> watchClientRequests({required String loungeId}) {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      return Stream.value([]);
    }

    late StreamController<List<ClientRequestModel>> controller;
    Timer? heartbeatTimer;
    StreamSubscription? notifSubscription;
    StreamSubscription? canteenSubscription;
    StreamSubscription? bookingsSubscription;

    void fetchAndEmit() async {
      try {
        final requests = await getClientRequests(loungeId: cleanLoungeId);
        if (!controller.isClosed) {
          controller.add(requests);
        }
      } catch (e) {
        debugPrint('⚠️ [REQUESTS_DATA_SOURCE] fetchAndEmit Error: $e');
      }
    }

    controller = StreamController<List<ClientRequestModel>>(
      onListen: () {
        // 1. Initial fetch & emit
        fetchAndEmit();

        // 2. Realtime Subscriptions for notifications, canteen_orders, and bookings
        try {
          notifSubscription = client
              .from('notifications')
              .stream(primaryKey: ['id'])
              .eq('lounge_id', cleanLoungeId)
              .listen((_) {
                fetchAndEmit();
              }, onError: (e) {
                debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Notifications Realtime Error: $e');
              });

          canteenSubscription = client
              .from('canteen_orders')
              .stream(primaryKey: ['id'])
              .eq('lounge_id', cleanLoungeId)
              .listen((_) {
                fetchAndEmit();
              }, onError: (e) {
                debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Canteen Realtime Error: $e');
              });

          bookingsSubscription = client
              .from('bookings')
              .stream(primaryKey: ['id'])
              .eq('lounge_id', cleanLoungeId)
              .listen((_) {
                fetchAndEmit();
              }, onError: (e) {
                debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Bookings Realtime Error: $e');
              });
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Realtime Listen Exception: $e');
        }

        // 3. Heartbeat Timer (every 5 seconds) to guarantee real-time updates even if WebSockets drop
        heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          fetchAndEmit();
        });
      },
      onCancel: () {
        notifSubscription?.cancel();
        canteenSubscription?.cancel();
        bookingsSubscription?.cancel();
        heartbeatTimer?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<List<ClientRequestModel>> getClientRequests({required String loungeId}) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) return [];

    try {
      final notifResponse = await client
          .from('notifications')
          .select()
          .eq('lounge_id', cleanLoungeId)
          .order('created_at', ascending: false)
          .limit(30);

      final notifList = (notifResponse as List)
          .map((json) => ClientRequestModel.fromNotificationJson(Map<String, dynamic>.from(json)))
          .toList();

      final ordersResponse = await client
          .from('canteen_orders')
          .select()
          .eq('lounge_id', cleanLoungeId)
          .order('created_at', ascending: false)
          .limit(30);

      final ordersList = (ordersResponse as List)
          .map((json) => ClientRequestModel.fromCanteenOrderJson(Map<String, dynamic>.from(json)))
          .toList();

      final extensionsResponse = await client
          .from('bookings')
          .select()
          .eq('lounge_id', cleanLoungeId)
          .eq('extension_status', 'pending')
          .order('updated_at', ascending: false)
          .limit(30);

      final extensionsList = (extensionsResponse as List)
          .map((json) => ClientRequestModel.fromBookingExtensionJson(Map<String, dynamic>.from(json)))
          .toList();

      final combined = [...notifList, ...ordersList, ...extensionsList];
      combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return combined;
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] getClientRequests Error: $e');
      return [];
    }
  }

  @override
  Future<void> markRequestAsAttended(String id, {bool isCanteenOrder = false}) async {
    debugPrint('🔵 [REQUESTS_DATA_SOURCE] Marking request as attended: id=$id, isCanteenOrder=$isCanteenOrder');
    try {
      if (id.startsWith('ext_')) {
        final bookingId = id.replaceFirst('ext_', '');
        await client
            .from('bookings')
            .update({
              'extension_status': 'approved',
            })
            .eq('id', bookingId);
      } else if (isCanteenOrder) {
        await client
            .from('canteen_orders')
            .update({
              'status': 'completed',
              'is_attended': true,
            })
            .eq('id', id);
      } else {
        await client
            .from('notifications')
            .update({
              'is_read': true,
              'is_attended': true,
            })
            .eq('id', id);
      }
      debugPrint('🟢 [REQUESTS_DATA_SOURCE] Successfully marked request $id as attended');
    } catch (e) {
      debugPrint('🔴 [REQUESTS_DATA_SOURCE] Failed to mark request $id as attended: $e');
      rethrow;
    }
  }
}
