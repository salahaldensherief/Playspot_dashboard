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
    final controller = StreamController<List<BookingModel>>();

    // 1. جلب البيانات الأولية فوراً عند فتح الصفحة
    _fetchAndEmit(controller, loungeId);

    // 2. الاشتراك في التغييرات اللحظية
    _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((_) {
          // فور حدوث أي تغيير (إضافة، تعديل، حذف)، نعيد جلب البيانات كاملة من الـ RPC
          _fetchAndEmit(controller, loungeId);
        });

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
