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
    Timer? backupSyncTimer;
    Timer? debounceTimer;
    StreamSubscription? realtimeSubscription;
    bool isFetching = false;

    void debouncedFetchAndEmit() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        if (isFetching || controller.isClosed) return;
        isFetching = true;
        try {
          await _fetchAndEmit(controller, loungeId);
        } finally {
          isFetching = false;
        }
      });
    }

    void cancelResources() {
      debounceTimer?.cancel();
      backupSyncTimer?.cancel();
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
                debouncedFetchAndEmit();
              }, onError: (e) {
                // Ignore silent socket drops; backup timer will continue polling
              });
        } catch (e) {
          // Ignore stream setup errors; backup polling will fetch updates
        }

        // 3. Periodic 30-second fallback backup poll (safety net for socket drops)
        backupSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          debouncedFetchAndEmit();
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
