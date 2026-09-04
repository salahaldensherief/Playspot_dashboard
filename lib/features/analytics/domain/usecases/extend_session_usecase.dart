import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/analytics/domain/repositories/dashboard_repository.dart';

class ExtendSessionUseCase {
  final DashboardRepository repository;

  ExtendSessionUseCase(this.repository);

  Future<Either<Failure, void>> call(String bookingId, int additionalMinutes, {double? additionalCost}) {
    return repository.extendSession(bookingId, additionalMinutes, additionalCost: additionalCost);
  }
}
