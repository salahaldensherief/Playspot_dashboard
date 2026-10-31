import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/analytics/domain/repositories/dashboard_repository.dart';

class StartOpenTimeSessionUseCase {
  final DashboardRepository repository;

  StartOpenTimeSessionUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String roomId,
    String? customerName,
    String? customerPhone,
    String playMode = 'single',
  }) {
    return repository.startOpenTimeSession(
      roomId: roomId,
      customerName: customerName,
      customerPhone: customerPhone,
      playMode: playMode,
    );
  }
}
