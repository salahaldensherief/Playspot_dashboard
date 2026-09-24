import 'package:flutter/foundation.dart';
import 'package:play_spot_dashboard/core/constants/app_constants.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingQueryHelper {
  final SupabaseClient client;

  BookingQueryHelper(this.client);

  Future<List<BookingModel>> fetchSafeSelect({
    String? loungeId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = client.from('bookings').select('''
        *,
        booking_items(id, name, quantity, price, total_price, status),
        canteen_orders(*),
        rooms(name, name_en, controllers_count, screen_size),
        lounges(name, location, location_point),
        profiles(full_name, phone, email)
      ''');
      if (loungeId != null && loungeId.isNotEmpty) {
        query = query.eq('lounge_id', loungeId);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e2) {
      debugPrint('⚠️ [BookingQueryHelper] Join query failed ($e2), attempting plain select fallback...');
      try {
        var query = client.from('bookings').select();
        if (loungeId != null && loungeId.isNotEmpty) {
          query = query.eq('lounge_id', loungeId);
        }
        if (status != null) {
          query = query.eq('status', status);
        }
        final response = await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        return (response as List)
            .map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      } catch (e3) {
        debugPrint('${AppConstants.criticalFallbackError}$e3');
        return [];
      }
    }
  }
}
