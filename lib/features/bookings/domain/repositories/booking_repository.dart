import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

abstract class BookingRepository {
  Future<Either<Failure, List<Booking>>> getBookings({
    String? loungeId,
    String? status,
    int limit = 50,
    int offset = 0,
  });
  Stream<List<Booking>> watchBookings({String? loungeId});
  Future<Either<Failure, void>> updateBookingStatus(String id, BookingStatus status);
  Future<Either<Failure, void>> confirmCashPayment(
    String bookingId, {
    String? shiftId,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
  });
  Future<Either<Failure, void>> createBooking(Booking booking);
  Future<Either<Failure, void>> swapRoom(String bookingId, String newRoomId, String actionBy);
  Future<Either<Failure, void>> startBookingSession(String bookingId);
  Future<Either<Failure, void>> autoCancelExpiredBookings();
}
