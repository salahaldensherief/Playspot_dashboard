import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/customer_cancellation_summary.dart';

abstract class BookingRepository {
  Future<Either<Failure, List<Booking>>> getBookings({
    String? loungeId,
    String? status,
    int limit = 50,
    int offset = 0,
  });
  Future<Either<Failure, PaginatedResult<Booking>>> getLoungeBookingsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  });
  Future<Either<Failure, CustomerCancellationSummary>> getBookingCancellationSummary({
    required String loungeId,
    required String userId,
  });
  Stream<List<Booking>> watchBookings({String? loungeId});
  Future<Either<Failure, void>> updateBookingStatus(String id, BookingStatus status);
  Future<Either<Failure, void>> approveBooking(String id);
  Future<Either<Failure, void>> confirmCashPayment(
    String bookingId, {
    String? shiftId,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
  });
  Future<Either<Failure, void>> createBooking(Booking booking);
  Future<Either<Failure, Map<String, dynamic>>> validateVoucherByCode(String voucherCode);
  Future<Either<Failure, void>> consumeVoucherByCode(String voucherCode, String bookingId);
  Future<Either<Failure, Map<String, dynamic>>> calculateBookingTotal({
    required String roomId,
    required double durationHours,
    String? voucherCode,
    double manualDiscount = 0.0,
    String? manualDiscountReason,
  });
  Future<Either<Failure, Map<String, dynamic>>> verifyAndHoldSlot({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
    String? userId,
    int holdMinutes = 10,
  });
  Future<Either<Failure, void>> swapRoom(String bookingId, String newRoomId, String actionBy);
  Future<Either<Failure, void>> startBookingSession(String bookingId);
  Future<Either<Failure, void>> autoCancelExpiredBookings();
  Future<Either<Failure, void>> approveManualBooking(String bookingId, String actionBy);
  Future<Either<Failure, void>> rejectManualBooking(String bookingId, String reason, String actionBy);
}
