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
  Future<List<Map<String, dynamic>>> getBookingItems(String bookingId);
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
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    try {
      // المحاولة الأساسية عبر الـ RPC
      final response = await client.rpc('get_all_bookings_admin', params: {
        'p_status': status,
        'p_lounge_id': cleanLoungeId,
        'p_limit': limit,
        'p_offset': offset,
      });

      return (response as List).map((json) {
        return BookingModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      // خطة بديلة (Fallback) في حالة فشل الـ RPC
      debugPrint('${AppConstants.bookingFetchAlert}$e');
      return _fetchSafeSelect(cleanLoungeId, status, limit, offset);
    }
  }

  Future<List<BookingModel>> _fetchSafeSelect(String? loungeId, String? status, int limit, int offset) async {
    try {
      var query = client.from('bookings').select('*, booking_items(*, canteen_items(*)), profiles(full_name, phone, email), rooms(name, name_en, controllers_count, screen_size), lounges(name, location, location_point)');
      if (loungeId != null && loungeId.isNotEmpty) {
        query = query.eq('lounge_id', loungeId);
      }
      
      if (status != null) {
        query = query.eq('status', status);
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List).map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e2) {
      debugPrint('⚠️ [DATA_SOURCE] _fetchSafeSelect join query failed ($e2), attempting plain select fallback...');
      try {
        var query = client.from('bookings').select();
        if (loungeId != null && loungeId.isNotEmpty) {
          query = query.eq('lounge_id', loungeId);
        }
        if (status != null) {
          query = query.eq('status', status);
        }
        final response = await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        return (response as List).map((json) => BookingModel.fromJson(Map<String, dynamic>.from(json))).toList();
      } catch (e3) {
        debugPrint('${AppConstants.criticalFallbackError}$e3');
        return [];
      }
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
        'p_shift_id': shiftId,
        'p_discount_amount': discountAmount ?? 0,
        'p_discount_percentage': discountPercentage ?? 0,
        'p_discount_reason': discountReason,
      });
      debugPrint('🟢 [DATA_SOURCE] RPC confirm_cash_payment succeeded');
    } catch (e) {
      debugPrint('⚠️ [DATA_SOURCE] RPC confirm_cash_payment failed ($e), attempting direct update fallback...');
      final updateData = {
        'payment_status': 'paid',
        'discount_amount': discountAmount,
        'discount_percentage': discountPercentage,
        'discount_reason': discountReason,
        'shift_id': shiftId,
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
    // Validate active shift for lounge before allowing booking creation
    final activeShift = await client
        .from('shifts')
        .select('id')
        .eq('lounge_id', booking.loungeId)
        .or('status.eq.open,status.eq.active')
        .limit(1)
        .maybeSingle();

    if (activeShift == null) {
      throw Exception('لا توجد وردية مفتوحة حالياً لهذا المقر. يرجى فتح وردية أولاً قبل إضافة أي حجز.');
    }

    final activeShiftId = activeShift['id']?.toString();
    final bookingToInsert = (activeShiftId != null && (booking.shiftId == null || booking.shiftId!.isEmpty))
        ? BookingModel(
            id: booking.id,
            userId: booking.userId,
            userName: booking.userName,
            userEmail: booking.userEmail,
            userPhone: booking.userPhone,
            loungeId: booking.loungeId,
            roomId: booking.roomId,
            loungeName: booking.loungeName,
            loungeLocation: booking.loungeLocation,
            roomName: booking.roomName,
            controllersCount: booking.controllersCount,
            screenSize: booking.screenSize,
            date: booking.date,
            startTime: booking.startTime,
            endTime: booking.endTime,
            durationMinutes: booking.durationMinutes,
            status: booking.status,
            paymentStatus: booking.paymentStatus,
            totalPrice: booking.totalPrice,
            voucherDiscount: booking.voucherDiscount,
            discountAmount: booking.discountAmount,
            discountPercentage: booking.discountPercentage,
            discountReason: booking.discountReason,
            extras: booking.extras,
            lat: booking.lat,
            lng: booking.lng,
            shiftId: activeShiftId,
            playMode: booking.playMode,
            roomPrice: booking.roomPrice,
          )
        : booking;

    await client.from('bookings').insert(bookingToInsert.toJson());
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

  @override
  Future<List<Map<String, dynamic>>> getBookingItems(String bookingId) async {
    try {
      final response = await client
          .from('booking_items')
          .select('*, canteen_items(*)')
          .eq('booking_id', bookingId);
          
      return (response as List).map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint('⚠️ [DATA_SOURCE] getBookingItems query failed: $e');
      return [];
    }
  }
}
