import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/analytics/domain/entities/lounge_stats_entity.dart';
import 'package:play_spot_dashboard/features/analytics/domain/repositories/dashboard_repository.dart';

class GetLoungeOwnerStatsUseCase {
  final DashboardRepository repository;

  GetLoungeOwnerStatsUseCase(this.repository);

  Future<Either<Failure, LoungeStatsEntity>> call(String? loungeId) {
    return repository.getLoungeStats(loungeId);
  }
}
