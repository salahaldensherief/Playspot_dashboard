import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<List<BookingModel>> getBookings({String? loungeId});
  Future<void> updateBookingStatus(String id, String status);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final SupabaseClient client;

  BookingRemoteDataSourceImpl(this.client);

  @override
  Future<List<BookingModel>> getBookings({String? loungeId}) async {
    var query = client.from('bookings').select();
    if (loungeId != null) {
      query = query.eq('lounge_id', loungeId);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => BookingModel.fromJson(json)).toList();
  }

  @override
  Future<void> updateBookingStatus(String id, String status) async {
    await client.from('bookings').update({'status': status}).eq('id', id);
  }
}
