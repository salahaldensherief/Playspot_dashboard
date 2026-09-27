import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/analytics/domain/repositories/dashboard_repository.dart';

class WatchActiveSessionsUseCase {
  final DashboardRepository repository;

  WatchActiveSessionsUseCase(this.repository);

  Stream<List<Booking>> call({String? loungeId}) {
    return repository.watchActiveSessions(loungeId: loungeId);
  }
}
