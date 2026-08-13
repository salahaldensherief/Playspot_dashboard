import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class CreateBooking {
  final BookingRepository repository;

  CreateBooking(this.repository);

  Future<Either<Failure, void>> call(Booking booking) async {
    return await repository.createBooking(booking);
  }
}
