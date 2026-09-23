import 'package:flutter/foundation.dart';
import 'package:play_spot_dashboard/features/requests/data/models/client_request_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestsFallbackFetcher {
  final SupabaseClient client;

  RequestsFallbackFetcher(this.client);

  Future<List<ClientRequestModel>> fetchPendingExtensionRequests(String loungeId) async {
    try {
      final response = await client.rpc('get_pending_extension_requests');
      if (response is List) {
        return response
            .map((json) {
              final map = Map<String, dynamic>.from(json);
              return ClientRequestModel.fromBookingExtensionJson(map);
            })
            .where((req) => req.loungeId.isEmpty || req.loungeId == loungeId)
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ [RequestsFallbackFetcher] get_pending_extension_requests RPC error ($e), fallback to bookings');
      try {
        final response = await client
            .from('bookings')
            .select('*, rooms(name, name_en)')
            .eq('lounge_id', loungeId)
            .eq('extension_status', 'pending');
        return (response as List).map((json) {
          final map = Map<String, dynamic>.from(json);
          return ClientRequestModel.fromBookingExtensionJson(map);
        }).toList();
      } catch (e2) {
        debugPrint('⚠️ [RequestsFallbackFetcher] fallback bookings select error: $e2');
      }
    }
    return [];
  }

  Future<List<ClientRequestModel>> fetchFallbackRequests(String loungeId) async {
    final List<ClientRequestModel> results = [];

    // 1. Fetch service_calls (Staff calls, assistance, etc.)
    try {
      final res = await client
          .from('service_calls')
          .select('*, bookings(lounge_id, room_id, rooms(name, name_en))')
          .neq('status', 'resolved')
          .neq('status', 'completed');

      for (var json in (res as List)) {
        final map = Map<String, dynamic>.from(json);
        final booking = map['bookings'] as Map<String, dynamic>?;
        final String? bLoungeId = (map['lounge_id'] ?? booking?['lounge_id'])?.toString();

        if (bLoungeId == loungeId) {
          final isAttended = map['is_attended'] == true || map['is_read'] == true;
          if (!isAttended) {
            final String? rName = booking?['rooms']?['name'];
            final String? uName = map['user_name'] ?? booking?['profiles']?['full_name'];
            final String? uPhone = map['user_phone'] ?? booking?['profiles']?['phone'];
            final String rawId = map['id']?.toString() ?? '';
            map['id'] = rawId.startsWith('sc_') ? rawId : 'sc_$rawId';
            map['lounge_id'] = loungeId;
            if (rName != null) map['room_name'] = rName;
            if (uName != null) map['user_name'] = uName;
            if (uPhone != null) map['user_phone'] = uPhone;
            map['type'] = 'service_call';
            results.add(ClientRequestModel.fromServiceCallJson(map));
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [RequestsFallbackFetcher] fallback service_calls error: $e');
    }

    // 2. Fetch canteen_orders
    try {
      final res = await client
          .from('canteen_orders')
          .select('*, bookings(lounge_id, room_id, rooms(name, name_en))')
          .or('status.eq.pending,status.eq.new,status.eq.in_progress');

      for (var json in (res as List)) {
        final map = Map<String, dynamic>.from(json);
        final booking = map['bookings'] as Map<String, dynamic>?;
        final String? bLoungeId = (map['lounge_id'] ?? booking?['lounge_id'])?.toString();

        if (bLoungeId == loungeId) {
          final isAttended = map['is_attended'] == true || map['is_read'] == true;
          if (!isAttended) {
            final String? rName = booking?['rooms']?['name'];
            final String? uName = map['user_name'];
            final String? uPhone = map['user_phone'];
            final String rawId = map['id']?.toString() ?? '';
            map['id'] = rawId.startsWith('canteen_') ? rawId : 'canteen_$rawId';
            map['lounge_id'] = loungeId;
            if (rName != null) map['room_name'] = rName;
            if (uName != null) map['user_name'] = uName;
            if (uPhone != null) map['user_phone'] = uPhone;
            map['type'] = 'canteen_order';
            results.add(ClientRequestModel.fromCanteenOrderJson(map));
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [RequestsFallbackFetcher] fallback canteen_orders error: $e');
    }

    // 3. Fetch client_requests
    try {
      final res = await client
          .from('client_requests')
          .select('*, bookings(lounge_id, room_id, rooms(name, name_en))')
          .neq('status', 'resolved')
          .neq('status', 'completed');

      for (var json in (res as List)) {
        final map = Map<String, dynamic>.from(json);
        final booking = map['bookings'] as Map<String, dynamic>?;
        final String? bLoungeId = (map['lounge_id'] ?? booking?['lounge_id'])?.toString();

        if (bLoungeId == loungeId) {
          final isAttended = map['is_attended'] == true || map['is_read'] == true;
          if (!isAttended) {
            final String? rName = map['rooms']?['name'] ?? booking?['rooms']?['name'];
            final String? uName = map['profiles']?['full_name'];
            final String? uPhone = map['profiles']?['phone'];
            final String rawId = map['id']?.toString() ?? '';
            map['id'] = rawId.startsWith('req_') ? rawId : 'req_$rawId';
            map['lounge_id'] = loungeId;
            if (rName != null) map['room_name'] = rName;
            if (uName != null) map['user_name'] = uName;
            if (uPhone != null) map['user_phone'] = uPhone;
            results.add(ClientRequestModel.fromNotificationJson(map));
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [RequestsFallbackFetcher] fallback client_requests error: $e');
    }

    // 4. Fetch booking_items (Extra snacks/items ordered during session)
    try {
      final res = await client
          .from('booking_items')
          .select('*, bookings!inner(lounge_id, room_id, rooms(name, name_en))')
          .eq('status', 'pending');

      for (var json in (res as List)) {
        final map = Map<String, dynamic>.from(json);
        final booking = map['bookings'] as Map<String, dynamic>?;
        final String? bLoungeId = booking?['lounge_id']?.toString();

        if (bLoungeId == loungeId) {
          final isAttended = map['is_attended'] == true || map['is_read'] == true;
          if (!isAttended) {
            final String? rName = booking?['rooms']?['name'];
            final String? uName = null;
            final String? uPhone = null;
            final String rawId = map['id']?.toString() ?? '';
            map['id'] = rawId.startsWith('item_') ? rawId : 'item_$rawId';
            map['lounge_id'] = loungeId;
            if (rName != null) map['room_name'] = rName;
            if (uName != null) map['user_name'] = uName;
            if (uPhone != null) map['user_phone'] = uPhone;
            map['type'] = 'canteen_order';
            map['items'] = [
              {
                'name': map['name'],
                'quantity': map['quantity'] ?? 1,
                'price': map['price'] ?? 0.0,
                'total_price': map['total_price'] ?? 0.0,
              }
            ];
            results.add(ClientRequestModel.fromCanteenOrderJson(map));
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [RequestsFallbackFetcher] fallback booking_items error: $e');
    }

    return results;
  }
}
