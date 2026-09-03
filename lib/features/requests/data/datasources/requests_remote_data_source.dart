import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_request_model.dart';

abstract class RequestsRemoteDataSource {
  /// Stream combined real-time notifications and canteen orders for a lounge.
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
    if (loungeId.isEmpty) {
      return Stream.value([]);
    }

    try {
      // Stream 1: Notifications
      final notificationStream = client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('lounge_id', loungeId)
          .map((list) {
            return list.map((json) => ClientRequestModel.fromNotificationJson(json)).toList();
          });

      // Stream 2: Canteen Orders
      final canteenOrderStream = client
          .from('canteen_orders')
          .stream(primaryKey: ['id'])
          .eq('lounge_id', loungeId)
          .map((list) {
            return list.map((json) => ClientRequestModel.fromCanteenOrderJson(json)).toList();
          });

      // Combine both streams into one unified sorted list
      return Rx.combineLatest2<List<ClientRequestModel>, List<ClientRequestModel>, List<ClientRequestModel>>(
        notificationStream,
        canteenOrderStream,
        (notifications, orders) {
          final combined = [...notifications, ...orders];
          combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return combined;
        },
      ).handleError((e) {
        debugPrint('⚠️ [DATA_SOURCE] Requests Stream Error: $e');
        return <ClientRequestModel>[];
      });
    } catch (e) {
      debugPrint('⚠️ [DATA_SOURCE] Error initializing requests stream: $e');
      return Stream.value([]);
    }
  }

  @override
  Future<List<ClientRequestModel>> getClientRequests({required String loungeId}) async {
    if (loungeId.isEmpty) return [];

    try {
      final notifResponse = await client
          .from('notifications')
          .select()
          .eq('lounge_id', loungeId)
          .order('created_at', ascending: false)
          .limit(30);

      final notifList = (notifResponse as List)
          .map((json) => ClientRequestModel.fromNotificationJson(Map<String, dynamic>.from(json)))
          .toList();

      final ordersResponse = await client
          .from('canteen_orders')
          .select()
          .eq('lounge_id', loungeId)
          .order('created_at', ascending: false)
          .limit(30);

      final ordersList = (ordersResponse as List)
          .map((json) => ClientRequestModel.fromCanteenOrderJson(Map<String, dynamic>.from(json)))
          .toList();

      final combined = [...notifList, ...ordersList];
      combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return combined;
    } catch (e) {
      debugPrint('⚠️ [DATA_SOURCE] getClientRequests Error: $e');
      return [];
    }
  }

  @override
  Future<void> markRequestAsAttended(String id, {bool isCanteenOrder = false}) async {
    debugPrint('🔵 [DATA_SOURCE] Marking request as attended: id=$id, isCanteenOrder=$isCanteenOrder');
    try {
      if (isCanteenOrder) {
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
      debugPrint('🟢 [DATA_SOURCE] Successfully marked request $id as attended');
    } catch (e) {
      debugPrint('🔴 [DATA_SOURCE] Failed to mark request $id as attended: $e');
      rethrow;
    }
  }
}
