import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lounge_stats_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetLoungeOwnerStatsUseCase {
  final DashboardRepository repository;

  GetLoungeOwnerStatsUseCase(this.repository);

  Future<Either<Failure, LoungeStatsEntity>> call(String? loungeId) {
    return repository.getLoungeStats(loungeId);
  }
}
