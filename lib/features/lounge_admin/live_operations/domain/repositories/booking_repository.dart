import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/booking.dart';

abstract class BookingRepository {
  Future<Either<Failure, List<Booking>>> getBookings({String? loungeId});
  Stream<List<Booking>> watchBookings({String? loungeId});
  Future<Either<Failure, void>> updateBookingStatus(String id, BookingStatus status);
}
