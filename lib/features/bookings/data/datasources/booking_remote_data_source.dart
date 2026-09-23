import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';
export 'booking_remote_data_source_impl.dart';

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

  Future<void> swapRoom(String bookingId, String newRoomId, String actionBy);

  Future<void> startBookingSession(String bookingId);

  Future<void> autoCancelExpiredBookings();

  Future<List<Map<String, dynamic>>> getBookingItems(String bookingId);
}