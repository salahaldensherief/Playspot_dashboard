import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/analytics/domain/repositories/dashboard_repository.dart';

class ReviewExtensionRequestUseCase {
  final DashboardRepository repository;

  ReviewExtensionRequestUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String bookingId,
    required bool isApproved,
    double? additionalCost,
    String? reason,
    int? requestedMinutes,
    int? currentDurationMinutes,
  }) {
    return repository.reviewExtensionRequest(
      bookingId: bookingId,
      isApproved: isApproved,
      additionalCost: additionalCost,
      reason: reason,
      requestedMinutes: requestedMinutes,
      currentDurationMinutes: currentDurationMinutes,
    );
  }
}
