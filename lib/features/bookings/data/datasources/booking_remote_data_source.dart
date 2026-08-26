import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
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
  Future<void> createBooking(BookingModel booking);
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
      // المحاولة الأساسية عبر الـ RPC
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
      // خطة بديلة (Fallback) في حالة فشل الـ RPC
      debugPrint('${AppConstants.bookingFetchAlert}$e');
      
      try {
        // نستخدم أبسط استعلام ممكن مع استبعاد booking_status تماماً إذا كان يسبب خطأ في النوع
        // ونعتمد على الحقل status الأصلي
        var query = client.from('bookings').select();

        if (loungeId != null) query = query.eq('lounge_id', loungeId);
        if (status != null) {
          query = query.eq('status', status);
        }
        
        final response = await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
        
        return (response as List).map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json))).toList();
      } catch (e2) {
        debugPrint('${AppConstants.criticalFallbackError}$e2');
        return []; // منع الشاشة الحمراء بإرجاع قائمة فارغة في حالة الفشل التام
      }
    }
  }

  @override
  Future<void> updateBookingStatus(String id, String status) async {
    // التحديث المباشر للجدول مع دعم مسمى الحقل الصحيح status
    await client.from('bookings').update({
      'status': status,
    }).eq('id', id);
  }

  @override
  Future<void> confirmCashPayment(String bookingId) async {
    try {
      await client.rpc('confirm_cash_payment', params: {'p_booking_id': bookingId});
    } catch (e) {
      // تحديث الجدول يدوياً إذا فشلت الـ RPC
      await client.from('payments').update({'status': 'paid'}).eq('booking_id', bookingId);
    }
  }

  @override
  Future<void> createBooking(BookingModel booking) async {
    await client.from('bookings').insert(booking.toJson());
  }
}
