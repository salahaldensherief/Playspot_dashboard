import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/analytics/domain/repositories/dashboard_repository.dart';

class EndSessionUseCase {
  final DashboardRepository repository;

  EndSessionUseCase(this.repository);

  Future<Either<Failure, void>> call(String bookingId) {
    return repository.endSession(bookingId);
  }
}
