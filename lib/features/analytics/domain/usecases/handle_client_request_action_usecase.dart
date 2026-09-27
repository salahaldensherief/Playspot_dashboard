import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/analytics/domain/repositories/dashboard_repository.dart';

class HandleClientRequestActionUseCase {
  final DashboardRepository repository;

  HandleClientRequestActionUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String requestId,
    required bool isCanteenOrder,
    required bool approve,
    String? bookingId,
    int? extensionMinutes,
    List<Map<String, dynamic>>? extraItems,
    double? extraCost,
  }) {
    return repository.handleClientRequestAction(
      requestId: requestId,
      isCanteenOrder: isCanteenOrder,
      approve: approve,
      bookingId: bookingId,
      extensionMinutes: extensionMinutes,
      extraItems: extraItems,
      extraCost: extraCost,
    );
  }
}
