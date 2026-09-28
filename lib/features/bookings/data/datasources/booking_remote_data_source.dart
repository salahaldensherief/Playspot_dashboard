import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/customer_cancellation_summary.dart';

abstract class BookingRemoteDataSource {
  Future<List<BookingModel>> getBookings({
    String? loungeId,
    String? status,
    int limit = 50,
    int offset = 0,
  });

  Future<PaginatedResult<BookingModel>> getLoungeBookingsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  });

  Future<CustomerCancellationSummary> getBookingCancellationSummary({
    required String loungeId,
    required String userId,
  });

  Future<void> updateBookingStatus(String id, String status);

  Future<void> approveBooking(String id);

  Future<void> confirmCashPayment(
    String bookingId, {
    String? shiftId,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
  });

  Future<void> createBooking(BookingModel booking);

  Future<Map<String, dynamic>> validateVoucherByCode(String voucherCode);

  Future<void> consumeVoucherByCode(String voucherCode, String bookingId);

  Future<Map<String, dynamic>> calculateBookingTotal({
    required String roomId,
    required double durationHours,
    String? voucherCode,
    double manualDiscount = 0.0,
    String? manualDiscountReason,
  });

  Future<Map<String, dynamic>> quoteBookingPrice({
    required String roomId,
    required String date,
    required String startTime,
    required String endTime,
    String playMode = 'single',
    int extraControllers = 0,
    String? couponCode,
  });

  Future<List<Map<String, dynamic>>> getRoomSlotsWithPrices({
    required String roomId,
    required String date,
  });

  Future<Map<String, dynamic>> getLoungePriceRange({
    required String loungeId,
  });

  Future<Map<String, dynamic>> verifyAndHoldSlot({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
    String? userId,
    int holdMinutes = 10,
  });

  Future<void> swapRoom(String bookingId, String newRoomId, String actionBy);

  Future<void> startBookingSession(String bookingId);

  Future<Map<String, dynamic>> startOpenTimeSession({
    required String roomId,
    String? customerName,
    String? customerPhone,
    String playMode = 'single',
  });

  Future<Map<String, dynamic>> completeOpenTimeSession(String bookingId);

  Future<void> autoCancelExpiredBookings();

  Future<void> approveManualBooking(String bookingId, String actionBy);

  Future<void> rejectManualBooking(String bookingId, String reason, String actionBy);

  Future<List<Map<String, dynamic>>> getBookingItems(String bookingId);
}
