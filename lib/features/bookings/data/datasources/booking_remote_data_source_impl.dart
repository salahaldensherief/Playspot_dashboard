import 'package:flutter/foundation.dart';
import 'package:play_spot_dashboard/core/constants/app_constants.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_mutation_helper.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_query_helper.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/customer_cancellation_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_remote_data_source.dart';

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final SupabaseClient client;
  late final BookingQueryHelper _queryHelper;
  late final BookingMutationHelper _mutationHelper;

  BookingRemoteDataSourceImpl(this.client) {
    _queryHelper = BookingQueryHelper(client);
    _mutationHelper = BookingMutationHelper(
      client: client,
      consumeVoucher: consumeVoucherByCode,
      validateVoucher: validateVoucherByCode,
    );
  }

  @override
  Future<PaginatedResult<BookingModel>> getLoungeBookingsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      return PaginatedResult.empty(requestedPage: page, requestedPageSize: pageSize);
    }

    final clampedPageSize = pageSize.clamp(1, 100);
    final validPage = page < 1 ? 1 : page;

    try {
      final response = await client.rpc('get_lounge_bookings_page', params: {
        'p_lounge_id': cleanLoungeId,
        'p_page': validPage,
        'p_page_size': clampedPageSize,
      });

      return PaginatedResult.fromRpcResponse<BookingModel>(
        response,
        mapper: (json) => BookingModel.fromJson(json),
        requestedPage: validPage,
        requestedPageSize: clampedPageSize,
      );
    } catch (e) {
      debugPrint('⚠️ [DATA_SOURCE] get_lounge_bookings_page RPC error ($e), falling back');
      final fallbackList = await getBookings(
        loungeId: cleanLoungeId,
        limit: clampedPageSize,
        offset: (validPage - 1) * clampedPageSize,
      );
      return PaginatedResult(
        items: fallbackList,
        totalCount: fallbackList.length,
        page: validPage,
        pageSize: clampedPageSize,
      );
    }
  }

  @override
  Future<CustomerCancellationSummary> getBookingCancellationSummary({
    required String loungeId,
    required String userId,
  }) async {
    final cleanLoungeId = loungeId.trim();
    final cleanUserId = userId.trim();
    if (cleanLoungeId.isEmpty || cleanUserId.isEmpty) {
      return CustomerCancellationSummary.empty();
    }

    try {
      final response = await client.rpc('get_booking_cancellation_summary', params: {
        'p_lounge_id': cleanLoungeId,
        'p_user_id': cleanUserId,
      });

      if (response is Map) {
        return CustomerCancellationSummary.fromJson(Map<String, dynamic>.from(response));
      }
      return CustomerCancellationSummary.empty();
    } catch (e) {
      debugPrint('⚠️ [DATA_SOURCE] get_booking_cancellation_summary error ($e)');
      return CustomerCancellationSummary.empty();
    }
  }

  @override
  Future<List<BookingModel>> getBookings({
    String? loungeId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    try {
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
      debugPrint('${AppConstants.bookingFetchAlert}$e');
      return _queryHelper.fetchSafeSelect(
        loungeId: cleanLoungeId,
        status: status,
        limit: limit,
        offset: offset,
      );
    }
  }

  @override
  Future<void> approveBooking(String id) async {
    debugPrint('🔵 [DATA_SOURCE] Approving booking id=$id (status=upcoming, payment_status=paid)');
    try {
      await client.from('bookings').update({
        'status': 'upcoming',
        'payment_status': 'paid',
      }).eq('id', id);
      debugPrint('🟢 [DATA_SOURCE] Booking approved successfully with payment_status=paid!');
    } catch (e) {
      debugPrint('⚠️ [DATA_SOURCE] Failed to approve booking directly ($e), calling updateBookingStatus...');
      await updateBookingStatus(id, 'upcoming');
    }
  }

  @override
  Future<void> updateBookingStatus(String id, String status) async {
    String cleanStatus = status.contains('.') ? status.split('.').last : status;
    cleanStatus = cleanStatus.trim().toLowerCase().replaceAll(' ', '_');

    if (cleanStatus == 'rejected' || cleanStatus == 'reject' || cleanStatus == 'canceled' || cleanStatus == 'no_show') {
      cleanStatus = 'cancelled';
    } else if (cleanStatus == 'inprogress' || cleanStatus == 'in_progress' || cleanStatus == 'active') {
      cleanStatus = 'in_progress';
    }

    const validDbStatuses = {'pending', 'upcoming', 'in_progress', 'completed', 'cancelled'};
    if (!validDbStatuses.contains(cleanStatus)) {
      debugPrint('⚠️ [DATA_SOURCE] Invalid status "$cleanStatus" provided for booking $id. Mapping to "cancelled".');
      cleanStatus = 'cancelled';
    }

    debugPrint('🔵 [DATA_SOURCE] Calling RPC update_booking_status_admin for id=$id, status=$cleanStatus');

    try {
      await client.rpc('update_booking_status_admin', params: {
        'p_booking_id': id,
        'p_status': cleanStatus,
      });
      debugPrint('🟢 [DATA_SOURCE] RPC Update Successful!');
    } catch (e) {
      if (e.toString().contains('shift') || e.toString().contains('الوردية')) {
        debugPrint('⚠️ [DATA_SOURCE] update_booking_status_admin failed due to shift requirement. Finding active shift and updating directly...');
        final shiftRes = await client
            .from('shifts')
            .select('id')
            .eq('status', 'open')
            .order('start_time', ascending: false)
            .limit(1)
            .maybeSingle();

        final shiftId = shiftRes?['id']?.toString();

        await client.from('bookings').update({
          'status': cleanStatus,
          'shift_id': shiftId,
        }).eq('id', id);
        debugPrint('🟢 [DATA_SOURCE] Direct booking status update with active shift successful!');
      } else {
        rethrow;
      }
    }

    // Automatically make the room available in rooms table if booking is cancelled or completed
    if (cleanStatus == 'cancelled' || cleanStatus == 'completed') {
      try {
        final bookingRes = await client.from('bookings').select('room_id').eq('id', id).maybeSingle();
        final roomId = bookingRes?['room_id']?.toString();
        if (roomId != null && roomId.isNotEmpty) {
          await client.from('rooms').update({'status': 'available'}).eq('id', roomId);
          debugPrint('🟢 [DATA_SOURCE] Room $roomId status reset to available in rooms table.');
        }
      } catch (e) {
        debugPrint('⚠️ [DATA_SOURCE] Failed to reset room status to available: $e');
      }
    }
  }

  @override
  Future<void> confirmCashPayment(
    String bookingId, {
    String? shiftId,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
  }) async {
    debugPrint('🔵 [DATA_SOURCE] Confirming payment for booking: $bookingId');
    try {
      await client.rpc('complete_booking_payment', params: {
        'p_booking_id': bookingId,
        'p_shift_id': shiftId,
        'p_payment_method': 'cash',
        'p_discount_amount': discountAmount ?? 0,
        'p_discount_percentage': discountPercentage ?? 0,
        'p_discount_reason': discountReason,
      });

      await client.from('bookings').update({
        'status': 'in_progress',
      }).eq('id', bookingId).eq('status', 'completed');

      debugPrint('🟢 [DATA_SOURCE] RPC complete_booking_payment succeeded & status safeguarded!');
      return;
    } catch (e1) {
      debugPrint('ℹ️ [DATA_SOURCE] complete_booking_payment failed ($e1), falling back to confirm_cash_payment...');
      try {
        await client.rpc('confirm_cash_payment', params: {
          'p_booking_id': bookingId,
          'p_shift_id': shiftId,
          'p_discount_amount': discountAmount ?? 0,
          'p_discount_percentage': discountPercentage ?? 0,
          'p_discount_reason': discountReason,
        });

        await client.from('bookings').update({
          'status': 'in_progress',
        }).eq('id', bookingId).eq('status', 'completed');

        debugPrint('🟢 [DATA_SOURCE] RPC confirm_cash_payment succeeded & status safeguarded!');
        return;
      } catch (e2) {
        debugPrint('⚠️ [DATA_SOURCE] RPC confirm_cash_payment failed ($e2), attempting direct update fallback...');
        final updateData = {
          'payment_status': 'paid',
          'status': 'in_progress',
          'discount_amount': discountAmount,
          'discount_percentage': discountPercentage,
          'discount_reason': discountReason,
          'shift_id': shiftId,
        };

        final res = await client.from('bookings').update(updateData).eq('id', bookingId).select();
        if ((res as List).isEmpty) {
          throw Exception('فشل تأكيد الدفع: لا توجد صلاحيات لتعديل الحجز (RLS Restricted)');
        }
      }
    }
  }

  @override
  Future<Map<String, dynamic>> validateVoucherByCode(String voucherCode) async {
    final cleanCode = voucherCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      throw Exception('يرجى إدخال كود القسيمة');
    }
    debugPrint('🔵 [DATA_SOURCE] Calling validate_voucher_by_code with p_code: $cleanCode');
    final response = await client.rpc('validate_voucher_by_code', params: {
      'p_code': cleanCode,
    });

    if (response is Map) {
      final resultMap = Map<String, dynamic>.from(response);
      final isValid = resultMap['is_valid'] ?? resultMap['valid'] ?? resultMap['success'] ?? true;
      if (isValid == false) {
        final errorMsg = resultMap['error'] ?? resultMap['message'] ?? resultMap['reason'] ?? 'كود القسيمة غير صالح أو منتهي الصلاحية';
        throw Exception(errorMsg);
      }
      return resultMap;
    }
    return {'is_valid': true};
  }

  @override
  Future<void> consumeVoucherByCode(String voucherCode, String bookingId) async {
    final cleanCode = voucherCode.trim().toUpperCase();
    if (cleanCode.isEmpty || bookingId.isEmpty) return;
    debugPrint('🔵 [DATA_SOURCE] Calling consume_voucher_by_code with p_code: $cleanCode, p_booking_id: $bookingId');
    await client.rpc('consume_voucher_by_code', params: {
      'p_code': cleanCode,
      'p_booking_id': bookingId,
    });
    debugPrint('🟢 [DATA_SOURCE] consume_voucher_by_code RPC executed successfully!');
  }

  @override
  Future<void> createBooking(BookingModel booking) async {
    return _mutationHelper.executeCreateBooking(booking);
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
    await client.rpc('start_booking_session', params: {
      'p_booking_id': bookingId,
    });
  }

  @override
  Future<void> autoCancelExpiredBookings() async {
    debugPrint('ℹ️ [DATA_SOURCE] autoCancelExpiredBookings is handled automatically by server-side Cron/Triggers.');
  }

  @override
  Future<List<Map<String, dynamic>>> getBookingItems(String bookingId) async {
    try {
      final response = await client
          .from('booking_items')
          .select('*, extras(*)')
          .eq('booking_id', bookingId);

      return (response as List).map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint('⚠️ [DATA_SOURCE] getBookingItems query failed: $e');
      return [];
    }
  }
}
