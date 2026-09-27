import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/paginated_result.dart';
import '../../../marketing/data/models/redemption_option_model.dart';
import '../models/loyalty_level_model.dart';
import '../models/loyalty_stats_model.dart';
import '../models/loyalty_task_model.dart';
import '../models/points_transaction_model.dart';
import '../models/referral_model.dart';
import 'loyalty_remote_data_source.dart';
import 'loyalty_stats_remote_helper.dart';
import 'loyalty_transactions_remote_helper.dart';

class LoyaltyRemoteDataSourceImpl implements LoyaltyRemoteDataSource {
  final SupabaseClient client;
  late final LoyaltyStatsRemoteHelper _statsHelper;
  late final LoyaltyTransactionsRemoteHelper _transactionsHelper;

  LoyaltyRemoteDataSourceImpl(this.client) {
    _statsHelper = LoyaltyStatsRemoteHelper(client);
    _transactionsHelper = LoyaltyTransactionsRemoteHelper(client);
  }

  @override
  Future<LoyaltyStatsModel> getLoyaltyStats({
    DateTime? startDate,
    DateTime? endDate,
    String? levelId,
    String? referralStatus,
    String? userId,
  }) => _statsHelper.getLoyaltyStats(
    startDate: startDate,
    endDate: endDate,
    levelId: levelId,
    referralStatus: referralStatus,
    userId: userId,
  );

  @override
  Future<List<ReferralModel>> getReferrals({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? userId,
  }) => _statsHelper.getReferrals(
    startDate: startDate,
    endDate: endDate,
    status: status,
    userId: userId,
  );

  @override
  Future<List<LoyaltyTaskModel>> getTasks() async {
    final response = await client
        .from('loyalty_tasks')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => LoyaltyTaskModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await client.from('loyalty_tasks').update(data).eq('id', id);
  }

  @override
  Future<List<LoyaltyLevelModel>> getLevels() async {
    final response = await client
        .from('loyalty_levels')
        .select()
        .order('min_points', ascending: true);

    return (response as List)
        .map((e) => LoyaltyLevelModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> updateLevel(String id, Map<String, dynamic> data) async {
    await client.from('loyalty_levels').update(data).eq('id', id);
  }

  @override
  Future<void> adjustUserPoints({
    required String userId,
    required int pointsDelta,
    required String reason,
  }) => _transactionsHelper.adjustUserPoints(
    userId: userId,
    pointsDelta: pointsDelta,
    reason: reason,
  );

  @override
  Future<PaginatedResult<PointsTransactionModel>> getPointsTransactionsPage({
    int page = 1,
    int pageSize = 20,
  }) => _transactionsHelper.getPointsTransactionsPage(
    page: page,
    pageSize: pageSize,
  );

  @override
  Future<List<RedemptionOptionModel>> getRedemptionOptions() async {
    final response = await client
        .from('redemption_options')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (e) => RedemptionOptionModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  @override
  Future<void> createRedemptionOption(RedemptionOptionModel option) async {
    await client.from('redemption_options').insert(option.toJson());
  }

  @override
  Future<void> updateRedemptionOption(
    String id,
    Map<String, dynamic> data,
  ) async {
    await client.from('redemption_options').update(data).eq('id', id);
  }

  @override
  Future<void> deleteRedemptionOption(String id) async {
    await client.from('redemption_options').delete().eq('id', id);
  }
}
