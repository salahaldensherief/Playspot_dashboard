import '../../../../core/streams/refreshing_stream.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import 'booking_remote_data_source.dart';

abstract class BookingRealtimeDataSource {
  Stream<List<BookingModel>> watchBookings({String? loungeId});
}

class BookingRealtimeDataSourceImpl implements BookingRealtimeDataSource {
  final SupabaseClient _client;
  final BookingRemoteDataSource _remoteDataSource;

  BookingRealtimeDataSourceImpl(this._client, this._remoteDataSource);

  @override
  Stream<List<BookingModel>> watchBookings({String? loungeId}) {
    final cleanLoungeId = loungeId?.trim();
    final scopedId = cleanLoungeId == null || cleanLoungeId.isEmpty
        ? null
        : cleanLoungeId;
    return refreshingStream<List<BookingModel>>(
      fetch: () => _remoteDataSource.getBookings(loungeId: scopedId),
      invalidations: () {
        var query = _client.from('bookings').stream(primaryKey: ['id']);
        if (scopedId != null) query = query.eq('lounge_id', scopedId);
        return query.order('created_at');
      },
    );
  }
}
