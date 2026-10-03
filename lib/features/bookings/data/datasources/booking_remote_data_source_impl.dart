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
  Future<Map<String, dynamic>> quoteBookingPrice({
    required String roomId,
    required String date,
    required String startTime,
    required String endTime,
    String playMode = 'single',
    int extraControllers = 0,
    String? couponCode,
  }) async {
    final response = await client.rpc(
      'quote_booking_price',
      params: {
        'p_room_id': roomId,
        'p_date': date,
        'p_start': startTime,
        'p_end': endTime,
        'p_play_mode': playMode,
        'p_extra_controllers': extraControllers,
        'p_coupon_code': couponCode,
      },
    );
    if (response is! Map) {
      throw const FormatException('Invalid booking quote response');
    }
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getRoomSlotsWithPrices({
    required String roomId,
    required String date,
  }) async {
    final response = await client.rpc(
      'get_room_slots_with_prices',
      params: {'p_room_id': roomId, 'p_date': date},
    );
    if (response is! List) {
      throw const FormatException('Invalid priced slots response');
    }
    return response
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getLoungePriceRange({
    required String loungeId,
  }) async {
    final response = await client.rpc(
      'get_lounge_price_range',
      params: {'p_lounge_id': loungeId},
    );
    if (response is! Map) {
      throw const FormatException('Invalid lounge price range response');
    }
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<PaginatedResult<BookingModel>> getLoungeBookingsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      return PaginatedResult.empty(
        requestedPage: page,
        requestedPageSize: pageSize,
      );
    }

    final clampedPageSize = pageSize.clamp(1, 100);
    final validPage = page < 1 ? 1 : page;

    try {
      final response = await client.rpc(
        'get_lounge_bookings_page',
        params: {
          'p_lounge_id': cleanLoungeId,
          'p_page': validPage,
          'p_page_size': clampedPageSize,
        },
      );

      return PaginatedResult.fromRpcResponse<BookingModel>(
        response,
        mapper: (json) => BookingModel.fromJson(json),
        requestedPage: validPage,
        requestedPageSize: clampedPageSize,
      );
    } catch (e) {
      debugPrint(
        '⚠️ [DATA_SOURCE] get_lounge_bookings_page RPC error ($e), falling back',
      );
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
      final response = await client.rpc(
        'get_booking_cancellation_summary',
        params: {'p_lounge_id': cleanLoungeId, 'p_user_id': cleanUserId},
      );

      if (response is Map) {
        return CustomerCancellationSummary.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
      return CustomerCancellationSummary.empty();
    } catch (e) {
      debugPrint(
        '⚠️ [DATA_SOURCE] get_booking_cancellation_summary error ($e)',
      );
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
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty)
        ? loungeId.trim()
        : null;

    try {
      final response = await client.rpc(
        'get_all_bookings_admin',
        params: {
          'p_lounge_id': cleanLoungeId,
          'p_status': status,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

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
    await client.rpc(
      'update_booking_status_admin',
      params: {'p_booking_id': id, 'p_status': 'upcoming'},
    );
  }

  @override
  Future<void> updateBookingStatus(String id, String status) async {
    String cleanStatus = status.contains('.') ? status.split('.').last : status;
    cleanStatus = cleanStatus.trim().toLowerCase().replaceAll(' ', '_');

    if (cleanStatus == 'rejected' ||
        cleanStatus == 'reject' ||
        cleanStatus == 'canceled' ||
        cleanStatus == 'no_show') {
      cleanStatus = 'cancelled';
    } else if (cleanStatus == 'inprogress' || cleanStatus == 'active') {
      cleanStatus = 'in_progress';
    }

    const validDbStatuses = {
      'pending',
      'upcoming',
      'in_progress',
      'completed',
      'cancelled',
    };
    if (!validDbStatuses.contains(cleanStatus)) {
      throw ArgumentError.value(status, 'status', 'Unsupported booking status');
    }

    await client.rpc(
      'update_booking_status_admin',
      params: {'p_booking_id': id, 'p_status': cleanStatus},
    );
  }

  @override
  Future<void> confirmCashPayment(
    String bookingId, {
    String? shiftId,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
  }) async {
    final fixedDiscount = discountAmount ?? 0;
    final percentageDiscount = discountPercentage ?? 0;
    final hasDiscount = fixedDiscount > 0 || percentageDiscount > 0;

    if (hasDiscount) {
      await client.rpc(
        'apply_booking_discount',
        params: {
          'p_booking_id': bookingId,
          'p_discount_amount': fixedDiscount,
          'p_discount_percentage': percentageDiscount,
          'p_discount_reason': discountReason,
        },
      );
    }

    await client.rpc(
      'complete_booking_payment',
      params: {'p_booking_id': bookingId, 'p_payment_method': 'cash'},
    );
  }

  @override
  Future<Map<String, dynamic>> validateVoucherByCode(String voucherCode) async {
    final cleanCode = voucherCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      throw Exception('يرجى إدخال كود القسيمة');
    }
    debugPrint(
      '🔵 [DATA_SOURCE] Calling validate_voucher_by_code with p_code: $cleanCode',
    );
    final response = await client.rpc(
      'validate_voucher_by_code',
      params: {'p_code': cleanCode},
    );

    if (response is Map) {
      final resultMap = Map<String, dynamic>.from(response);
      final isValid =
          resultMap['is_valid'] ??
          resultMap['valid'] ??
          resultMap['success'] ??
          false;
      if (isValid == false) {
        final errorMsg =
            resultMap['error'] ??
            resultMap['message'] ??
            resultMap['reason'] ??
            'كود القسيمة غير صالح أو منتهي الصلاحية';
        throw Exception(errorMsg);
      }
      return resultMap;
    }
    throw const FormatException('invalid_voucher_response');
  }

  @override
  Future<void> consumeVoucherByCode(
    String voucherCode,
    String bookingId,
  ) async {
    final cleanCode = voucherCode.trim().toUpperCase();
    if (cleanCode.isEmpty || bookingId.isEmpty) return;
    debugPrint(
      '🔵 [DATA_SOURCE] Calling consume_voucher_by_code with p_code: $cleanCode, p_booking_id: $bookingId',
    );
    await client.rpc(
      'consume_voucher_by_code',
      params: {'p_code': cleanCode, 'p_booking_id': bookingId},
    );
    debugPrint(
      '🟢 [DATA_SOURCE] consume_voucher_by_code RPC executed successfully!',
    );
  }

  @override
  Future<Map<String, dynamic>> calculateBookingTotal({
    required String roomId,
    required double durationHours,
    String? voucherCode,
    double manualDiscount = 0.0,
    String? manualDiscountReason,
  }) async {
    final cleanVoucherCode = voucherCode?.trim().toUpperCase();
    debugPrint(
      '🔵 [DATA_SOURCE] Calling calculate_booking_total for room: $roomId, duration: $durationHours hrs',
    );
    final response = await client.rpc(
      'calculate_booking_total',
      params: {
        'p_room_id': roomId,
        'p_duration_hours': durationHours,
        'p_voucher_code':
            (cleanVoucherCode != null && cleanVoucherCode.isNotEmpty)
            ? cleanVoucherCode
            : null,
        'p_manual_discount': manualDiscount,
        'p_manual_discount_reason': manualDiscountReason,
      },
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> verifyAndHoldSlot({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
    String? userId,
    int holdMinutes = 10,
  }) async {
    debugPrint(
      '🔵 [DATA_SOURCE] Calling verify_and_hold_slot for room: $roomId from $startTime to $endTime',
    );
    final response = await client.rpc(
      'verify_and_hold_slot',
      params: {
        'p_room_id': roomId,
        'p_start_time': startTime.toUtc().toIso8601String(),
        'p_end_time': endTime.toUtc().toIso8601String(),
        'p_user_id': (userId != null && userId.trim().isNotEmpty)
            ? userId.trim()
            : null,
        'p_hold_minutes': holdMinutes,
      },
    );

    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      final success = map['success'] == true;
      if (!success) {
        final msg =
            map['message']?.toString() ??
            'The selected time slot overlaps with an existing booking or hold.';
        throw Exception(msg);
      }
      return map;
    }
    return {'success': true};
  }

  @override
  Future<void> createBooking(BookingModel booking) async {
    return _mutationHelper.executeCreateBooking(booking);
  }

  @override
  Future<void> swapRoom(
    String bookingId,
    String newRoomId,
    String actionBy,
  ) async {
    await client.rpc(
      'swap_booking_room',
      params: {
        'p_booking_id': bookingId,
        'p_new_room_id': newRoomId,
        'p_action_by': actionBy,
      },
    );
  }

  @override
  Future<void> startBookingSession(String bookingId) async {
    final booking = await client
        .from('bookings')
        .select('is_open_time')
        .eq('id', bookingId)
        .single();
    final response = await client.rpc(
      booking['is_open_time'] == true
          ? 'start_open_time_booking_session'
          : 'start_booking_session',
      params: {'p_booking_id': bookingId},
    );
    if (response is! Map || response['success'] != true) {
      throw const FormatException('Invalid session start response');
    }
  }

  @override
  Future<Map<String, dynamic>> startOpenTimeSession({
    required String roomId,
    String? customerName,
    String? customerPhone,
    String playMode = 'single',
  }) async {
    final response = await client.rpc(
      'start_open_time_session',
      params: {
        'p_room_id': roomId,
        'p_customer_name': customerName,
        'p_customer_phone': customerPhone,
        'p_play_mode': playMode,
      },
    );

    if (response is! Map || response['success'] != true) {
      throw const FormatException('Invalid open-time start response');
    }
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> completeOpenTimeSession(String bookingId) async {
    final response = await client.rpc(
      'complete_booking_session',
      params: {
        'p_booking_id': bookingId,
        'p_action_by': client.auth.currentUser?.id,
      },
    );

    return response is Map
        ? Map<String, dynamic>.from(response)
        : throw const FormatException('Invalid session completion response');
  }

  @override
  Future<void> autoCancelExpiredBookings() async {
    debugPrint(
      'ℹ️ [DATA_SOURCE] autoCancelExpiredBookings is handled automatically by server-side Cron/Triggers.',
    );
  }

  @override
  Future<void> approveManualBooking(String bookingId, String actionBy) async {
    await client.rpc(
      'approve_manual_booking',
      params: {'p_booking_id': bookingId, 'p_action_by': actionBy},
    );
  }

  @override
  Future<void> rejectManualBooking(
    String bookingId,
    String reason,
    String actionBy,
  ) async {
    await client.rpc(
      'reject_manual_booking',
      params: {
        'p_booking_id': bookingId,
        'p_rejection_reason': reason,
        'p_action_by': actionBy,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getBookingItems(String bookingId) async {
    try {
      final response = await client
          .from('booking_items')
          .select('*, extras(*)')
          .eq('booking_id', bookingId);

      return (response as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [DATA_SOURCE] getBookingItems query failed: $e');
      return [];
    }
  }
}
