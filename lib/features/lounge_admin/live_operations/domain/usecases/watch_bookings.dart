import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class WatchBookings {
  final BookingRepository repository;

  WatchBookings(this.repository);

  Stream<List<Booking>> call({String? loungeId}) {
    return repository.watchBookings(loungeId: loungeId);
  }
}
