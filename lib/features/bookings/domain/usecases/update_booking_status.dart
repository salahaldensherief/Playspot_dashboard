import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class UpdateBookingStatus {
  final BookingRepository repository;

  UpdateBookingStatus(this.repository);

  Future<Either<Failure, void>> call(String id, BookingStatus status) async {
    return await repository.updateBookingStatus(id, status);
  }
}
