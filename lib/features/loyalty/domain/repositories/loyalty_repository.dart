import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/loyalty_stats_model.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';

abstract class LoyaltyRepository {
  Future<Either<Failure, LoyaltyStatsModel>> getLoyaltyStats();
  Future<Either<Failure, List<RedemptionOptionEntity>>> getRedemptionOptions();
  Future<Either<Failure, void>> createRedemptionOption(RedemptionOptionEntity option);
  Future<Either<Failure, void>> updateRedemptionOption(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteRedemptionOption(String id);
}
