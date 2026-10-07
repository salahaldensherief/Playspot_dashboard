import '../../../../core/streams/refreshing_stream.dart';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';

class ActiveSessionsStreamHelper {
  final SupabaseClient supabaseClient;

  ActiveSessionsStreamHelper(this.supabaseClient);

  Stream<List<BookingModel>> watchActiveSessions({String? loungeId}) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty)
        ? loungeId.trim()
        : null;
    return refreshingStream<List<BookingModel>>(
      fetch: () => fetchActiveSessions(loungeId: cleanLoungeId),
      invalidations: () {
        var query = supabaseClient.from('bookings').stream(primaryKey: ['id']);
        if (cleanLoungeId != null) query = query.eq('lounge_id', cleanLoungeId);
        return query;
      },
      onRealtimeError: (error) =>
          debugPrint('⚠️ [ActiveSessionsStreamHelper] Realtime Error: $error'),
    );
  }

  Future<List<BookingModel>> fetchActiveSessions({String? loungeId}) async {
    if (loungeId != null && loungeId.isNotEmpty) {
      // Scoped RPC supplies customer/order details and owns authorization.
      // A denial must not fall back to a weaker direct-table read.
      final response = await supabaseClient.rpc(
        'get_live_bookings_with_items',
        params: {'p_lounge_id': loungeId},
      );
      return (response as List)
          .map((row) => BookingModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    }
    final response = await supabaseClient
        .from('bookings')
        .select('''
      *,
      canteen_orders (
        id, items, total_price, note, status, created_at,
        canteen_order_items (
          id, quantity, unit_price, total_price, extra_id,
          extras (id, name, name_ar, name_en, price)
        )
      ),
      booking_items(id, name, quantity, price, total_price, status),
      rooms(name, name_en, controllers_count, screen_size),
      lounges(name, location, location_point)
    ''')
        .eq('status', 'in_progress')
        .order('created_at', ascending: false);
    // bookings.user_id references auth.users, not public.profiles. Batch visible
    // profiles under caller RLS rather than using a nonexistent relationship.
    final userIds = response
        .map((row) => row['user_id'])
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final profiles = <String, Map<String, dynamic>>{};
    if (userIds.isNotEmpty) {
      final rows = await supabaseClient
          .from('profiles')
          .select('id,full_name,phone,email')
          .inFilter('id', userIds);
      for (final row in rows) {
        profiles[row['id'].toString()] = Map<String, dynamic>.from(row);
      }
    }
    return response.map((row) {
      final json = Map<String, dynamic>.from(row);
      final profile = profiles[row['user_id']];
      if (profile != null) json['profiles'] = profile;
      return BookingModel.fromJson(json);
    }).toList();
  }
}
