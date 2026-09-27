import '../../../../core/utils/paginated_result.dart';
import '../../../marketing/data/models/redemption_option_model.dart';
import '../models/loyalty_level_model.dart';
import '../models/loyalty_stats_model.dart';
import '../models/loyalty_task_model.dart';
import '../models/points_transaction_model.dart';
import '../models/referral_model.dart';

abstract class LoyaltyRemoteDataSource {
  Future<LoyaltyStatsModel> getLoyaltyStats({
    DateTime? startDate,
    DateTime? endDate,
    String? levelId,
    String? referralStatus,
    String? userId,
  });

  Future<List<ReferralModel>> getReferrals({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? userId,
  });

  Future<List<LoyaltyTaskModel>> getTasks();

  Future<void> updateTask(String id, Map<String, dynamic> data);

  Future<List<LoyaltyLevelModel>> getLevels();

  Future<void> updateLevel(String id, Map<String, dynamic> data);

  Future<void> adjustUserPoints({
    required String userId,
    required int pointsDelta,
    required String reason,
  });

  Future<PaginatedResult<PointsTransactionModel>> getPointsTransactionsPage({
    int page = 1,
    int pageSize = 20,
  });

  Future<List<RedemptionOptionModel>> getRedemptionOptions();
  Future<void> createRedemptionOption(RedemptionOptionModel option);
  Future<void> updateRedemptionOption(String id, Map<String, dynamic> data);
  Future<void> deleteRedemptionOption(String id);
}
