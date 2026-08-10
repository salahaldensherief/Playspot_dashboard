import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<List<BookingModel>> getBookings({
    String? loungeId,
    String? status,
    int limit = 50,
    int offset = 0,
  });
  Future<void> updateBookingStatus(String id, String status);
  Future<void> confirmCashPayment(String bookingId);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final SupabaseClient client;

  BookingRemoteDataSourceImpl(this.client);

  @override
  Future<List<BookingModel>> getBookings({
    String? loungeId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await client.rpc('get_all_bookings_admin', params: {
        'p_status': status,
        'p_lounge_id': loungeId,
        'p_limit': limit,
        'p_offset': offset,
      });

      return (response as List).map((json) {
        return BookingModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      // Fallback if RPC is not available or fails
      var query = client.from('bookings').select();
      if (loungeId != null) {
        query = query.eq('lounge_id', loungeId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List).map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json))).toList();
    }
  }

  @override
  Future<void> updateBookingStatus(String id, String status) async {
    await client.from('bookings').update({'status': status}).eq('id', id);
  }

  @override
  Future<void> confirmCashPayment(String bookingId) async {
    await client.rpc('confirm_cash_payment', params: {'p_booking_id': bookingId});
  }
}
