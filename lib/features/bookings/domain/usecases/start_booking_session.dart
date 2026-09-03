import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/booking_repository.dart';

class StartBookingSession {
  final BookingRepository repository;

  StartBookingSession(this.repository);

  Future<Either<Failure, void>> call(String bookingId) async {
    return await repository.startBookingSession(bookingId);
  }
}
