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
  Future<void> confirmCashPayment(
    String bookingId, {
    String? shiftId,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
  });
  Future<void> createBooking(BookingModel booking);
  Future<void> swapRoom(String bookingId, String newRoomId, String actionBy);
  Future<void> startBookingSession(String bookingId);
  Future<void> autoCancelExpiredBookings();
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
    // Technical Guard: Skip RPC if loungeId is null (unless it's a super-admin context which we don't differentiate here yet)
    // This prevents "Not authorized" logs for staff with missing lounge_id
    if (loungeId == null || loungeId.isEmpty) {
      return _fetchSafeSelect(loungeId, status, limit, offset);
    }

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
      return _fetchSafeSelect(loungeId, status, limit, offset);
    }
  }

  Future<List<BookingModel>> _fetchSafeSelect(String? loungeId, String? status, int limit, int offset) async {
    try {
      // Technical Guard: If loungeId is null/empty, we should NOT return all bookings 
      // for a staff member. We return an empty list to maintain data isolation.
      if (loungeId == null || loungeId.isEmpty) {
        debugPrint('BookingRemoteDataSource: Skipping fetch, loungeId is null/empty');
        return [];
      }

      var query = client.from('bookings').select();
      query = query.eq('lounge_id', loungeId);
      
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

  @override
  Future<void> updateBookingStatus(String id, String status) async {
    String cleanStatus = status.contains('.') ? status.split('.').last : status;
    cleanStatus = cleanStatus.trim().toLowerCase().replaceAll(' ', '_');

    // Map rejected, canceled, no_show or non-standard values to valid DB enum 'cancelled'
    if (cleanStatus == 'rejected' || cleanStatus == 'reject' || cleanStatus == 'canceled' || cleanStatus == 'no_show') {
      cleanStatus = 'cancelled';
    } else if (cleanStatus == 'inprogress' || cleanStatus == 'in_progress' || cleanStatus == 'active') {
      cleanStatus = 'in_progress';
    }

    // Safety guard to guarantee only DB-recognized enum values are sent
    const validDbStatuses = {'pending', 'upcoming', 'in_progress', 'completed', 'cancelled'};
    if (!validDbStatuses.contains(cleanStatus)) {
      debugPrint('⚠️ [DATA_SOURCE] Invalid/unrecognized status "$cleanStatus" provided for booking $id. Mapping to "cancelled".');
      cleanStatus = 'cancelled';
    }

    debugPrint('🔵 [DATA_SOURCE] Calling RPC update_booking_status_admin for id=$id, status=$cleanStatus');

    await client.rpc('update_booking_status_admin', params: {
      'p_booking_id': id,
      'p_status': cleanStatus,
    });

    debugPrint('🟢 [DATA_SOURCE] RPC Update Successful!');
  }  @override
  @override
  Future<void> confirmCashPayment(
      String bookingId, {
        String? shiftId,
        double? discountAmount,
        double? discountPercentage,
        String? discountReason,
      }) async {
    debugPrint('🔵 [DATA_SOURCE] Confirming cash payment for: $bookingId');
    try {
      await client.rpc('confirm_cash_payment', params: {
        'p_booking_id': bookingId,
        if (shiftId != null) 'p_shift_id': shiftId,
        'p_discount_amount': discountAmount ?? 0,
        'p_discount_percentage': discountPercentage ?? 0,
        'p_discount_reason': discountReason,
      });
      debugPrint('🟢 [DATA_SOURCE] RPC confirm_cash_payment succeeded');
    } catch (e) {
      debugPrint('⚠️ [DATA_SOURCE] RPC confirm_cash_payment failed ($e), attempting direct update fallback...');
      final updateData = {
        'payment_status': 'paid',
        if (discountAmount != null) 'discount_amount': discountAmount,
        if (discountPercentage != null) 'discount_percentage': discountPercentage,
        if (discountReason != null) 'discount_reason': discountReason,
        if (shiftId != null) 'shift_id': shiftId,
      };

      final res = await client.from('bookings').update(updateData).eq('id', bookingId).select();
      debugPrint('🟢 [DATA_SOURCE] Direct update fallback response: $res');

      if ((res as List).isEmpty) {
        throw Exception('فشل تأكيد الدفع: لا توجد صلاحيات لتعديل الحجز (RLS Restricted)');
      }
    }
  }
  @override
  Future<void> createBooking(BookingModel booking) async {
    await client.from('bookings').insert(booking.toJson());
  }

  @override
  Future<void> swapRoom(String bookingId, String newRoomId, String actionBy) async {
    await client.rpc('swap_booking_room', params: {
      'p_booking_id': bookingId,
      'p_new_room_id': newRoomId,
      'p_action_by': actionBy,
    });
  }

  @override
  Future<void> startBookingSession(String bookingId) async {
    debugPrint('🔵 [DATA_SOURCE] Calling RPC start_booking_session for bookingId=$bookingId');
    await client.rpc('start_booking_session', params: {
      'p_booking_id': bookingId,
    });
    debugPrint('🟢 [DATA_SOURCE] RPC start_booking_session successful!');
  }

  @override
  Future<void> autoCancelExpiredBookings() async {
    try {
      debugPrint('🔵 [DATA_SOURCE] Invoking RPC auto_cancel_expired_bookings...');
      await client.rpc('auto_cancel_expired_bookings');
      debugPrint('🟢 [DATA_SOURCE] RPC auto_cancel_expired_bookings completed successfully');
    } catch (e) {
      debugPrint('⚠️ [DATA_SOURCE] RPC auto_cancel_expired_bookings failed: $e');
    }
  }
}
