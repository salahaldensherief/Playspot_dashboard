import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

abstract class BookingRealtimeDataSource {
  Stream<List<BookingModel>> watchBookings({String? loungeId});
}

class BookingRealtimeDataSourceImpl implements BookingRealtimeDataSource {
  final SupabaseClient client;

  BookingRealtimeDataSourceImpl(this.client);

  @override
  Stream<List<BookingModel>> watchBookings({String? loungeId}) {
    // We can use both Postgres Changes (Stream) and Broadcast
    // For now, staying with Stream as it handles Initial data + changes
    // But adding broadcast capability if needed.
    
    final query = client.from('bookings').stream(primaryKey: ['id']);
    final stream = loungeId != null ? query.eq('lounge_id', loungeId) : query;

    return stream.map((event) {
      return event.map((json) => BookingModel.fromJson(json)).toList();
    });
  }

  void listenToBroadcast(String? loungeId, Function(Map<String, dynamic>) callback) {
    if (loungeId == null) return;
    client.channel('lounge_bookings_$loungeId')
      .onBroadcast(event: 'INSERT', callback: (payload) => callback(payload))
      .onBroadcast(event: 'UPDATE', callback: (payload) => callback(payload))
      .subscribe();
  }
}
