import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/paginated_result.dart';
import '../../data/models/loyalty_stats_model.dart';
import '../entities/referral_entity.dart';
import '../entities/loyalty_task_entity.dart';
import '../entities/loyalty_level_entity.dart';
import '../entities/points_transaction_entity.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';

abstract class LoyaltyRepository {
  Future<Either<Failure, LoyaltyStatsModel>> getLoyaltyStats({
    DateTime? startDate,
    DateTime? endDate,
    String? levelId,
    String? referralStatus,
    String? userId,
  });

  Future<Either<Failure, List<ReferralEntity>>> getReferrals({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? userId,
  });

  Future<Either<Failure, List<LoyaltyTaskEntity>>> getTasks();

  Future<Either<Failure, void>> updateTask(String id, Map<String, dynamic> data);

  Future<Either<Failure, List<LoyaltyLevelEntity>>> getLevels();

  Future<Either<Failure, void>> updateLevel(String id, Map<String, dynamic> data);

  Future<Either<Failure, void>> adjustUserPoints({
    required String userId,
    required int pointsDelta,
    required String reason,
  });

  Future<Either<Failure, PaginatedResult<PointsTransactionEntity>>> getPointsTransactionsPage({
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, List<RedemptionOptionEntity>>> getRedemptionOptions();
  Future<Either<Failure, void>> createRedemptionOption(RedemptionOptionEntity option);
  Future<Either<Failure, void>> updateRedemptionOption(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteRedemptionOption(String id);
}
