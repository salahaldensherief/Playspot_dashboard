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
    final stream = loungeId != null
        ? client.from('bookings').stream(primaryKey: ['id']).eq('lounge_id', loungeId)
        : client.from('bookings').stream(primaryKey: ['id']);

    return stream.map((event) {
      return event.map((json) => BookingModel.fromJson(json)).toList();
    });
  }
}
