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
        .from('loyalty_missions')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => LoyaltyTaskModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    const editable = {
      'title_ar',
      'title_en',
      'description_ar',
      'description_en',
      'points_reward',
      'is_active',
    };
    if (data.keys.any((key) => !editable.contains(key))) {
      throw ArgumentError('Unsupported loyalty mission field');
    }
    final payload = {
      for (final entry in data.entries)
        (entry.key == 'points_reward' ? 'reward_points' : entry.key):
            entry.value,
    };
    final updated = await client
        .from('loyalty_missions')
        .update(payload)
        .eq('id', id)
        .select('id')
        .maybeSingle();
    if (updated == null)
      throw const PostgrestException(
        message: 'Mission was not updated',
        code: 'P0002',
      );
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
    await _saveRedemptionOption(null, option);
  }

  @override
  Future<void> updateRedemptionOption(
    String id,
    Map<String, dynamic> data,
  ) async {
    final current = await client
        .from('redemption_options')
        .select()
        .eq('id', id)
        .single();
    final merged = <String, dynamic>{
      ...Map<String, dynamic>.from(current),
      ...data,
      'id': id,
    };
    await _saveRedemptionOption(id, RedemptionOptionModel.fromJson(merged));
  }

  Future<void> _saveRedemptionOption(
    String? id,
    RedemptionOptionModel option,
  ) async {
    await client.rpc(
      'save_redemption_option_admin',
      params: {
        'p_option_id': id,
        'p_title_ar': option.titleAr,
        'p_title_en': option.titleEn,
        'p_description_ar': option.descriptionAr,
        'p_description_en': option.descriptionEn,
        'p_points_cost': option.pointsCost,
        'p_reward_type': option.rewardType,
        'p_reward_value': option.rewardValue,
        'p_is_active': option.isActive,
      },
    );
  }

  @override
  Future<void> deleteRedemptionOption(String id) async {
    await client.rpc(
      'archive_redemption_option_admin',
      params: {'p_option_id': id},
    );
  }
}
