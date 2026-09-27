import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/analytics/domain/repositories/dashboard_repository.dart';

class AddExtrasToSessionUseCase {
  final DashboardRepository repository;

  AddExtrasToSessionUseCase(this.repository);

  Future<Either<Failure, void>> call(String bookingId, List<Map<String, dynamic>> extras, double additionalCost) {
    return repository.addExtrasToSession(bookingId, extras, additionalCost);
  }
}
