import 'dart:async';
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
    late StreamController<List<BookingModel>> controller;
    Timer? timer;
    StreamSubscription? realtimeSubscription;

    void cancelResources() {
      timer?.cancel();
      realtimeSubscription?.cancel();
    }

    controller = StreamController<List<BookingModel>>(
      onListen: () {
        // 1. Fetch initial data immediately on subscription
        _fetchAndEmit(controller, loungeId);

        // 2. Realtime postgres changes listener
        try {
          realtimeSubscription = _client
              .from('bookings')
              .stream(primaryKey: ['id'])
              .order('created_at')
              .listen((_) {
                _fetchAndEmit(controller, loungeId);
              }, onError: (e) {
                // Ignore silent socket drops; heartbeat timer will continue polling
              });
        } catch (e) {
          // Ignore stream setup errors; heartbeat polling will fetch updates
        }

        // 3. Periodic 5-second heartbeat poll to guarantee immediate live updates
        timer = Timer.periodic(const Duration(seconds: 5), (_) {
          _fetchAndEmit(controller, loungeId);
        });
      },
      onCancel: () {
        cancelResources();
      },
    );

    return controller.stream;
  }

  Future<void> _fetchAndEmit(StreamController<List<BookingModel>> controller, String? loungeId) async {
    try {
      final bookings = await _remoteDataSource.getBookings(loungeId: loungeId);
      if (!controller.isClosed) {
        controller.add(bookings);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }
}
