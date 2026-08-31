import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lounge_stats_entity.dart';

abstract class DashboardRepository {
  Future<Either<Failure, LoungeStatsEntity>> getLoungeStats(String? loungeId);
}
