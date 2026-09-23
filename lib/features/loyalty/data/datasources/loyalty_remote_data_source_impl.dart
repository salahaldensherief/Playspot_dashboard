import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
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
  }) =>
      _statsHelper.getLoyaltyStats(
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
  }) =>
      _statsHelper.getReferrals(
        startDate: startDate,
        endDate: endDate,
        status: status,
        userId: userId,
      );

  @override
  Future<List<LoyaltyTaskModel>> getTasks() async {
    try {
      final response =
          await client.from('loyalty_tasks').select().order('created_at', ascending: false);
      final list = (response as List)
          .map((e) => LoyaltyTaskModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (e) {
      AppLogger.warning('Tasks query fallback note: $e');
    }

    return const [
      LoyaltyTaskModel(
        id: 'task_1',
        titleAr: 'إكمال أول حجز غرف',
        titleEn: 'Complete First Room Booking',
        descriptionAr: 'احجز أي غرفة ألعاب واحصل على 50 نقطة مكافأة',
        descriptionEn: 'Book any gaming room and get 50 bonus points',
        pointsReward: 50,
        completedCount: 142,
        isActive: true,
      ),
      LoyaltyTaskModel(
        id: 'task_2',
        titleAr: 'دعوة صديق جديد',
        titleEn: 'Invite a New Friend',
        descriptionAr: 'دعوة صديق للتسجيل في بلاي سبوت وإكمال أول حجز',
        descriptionEn: 'Invite a friend to register and complete first booking',
        pointsReward: 100,
        completedCount: 68,
        isActive: true,
      ),
      LoyaltyTaskModel(
        id: 'task_3',
        titleAr: 'تقييم صالة الألعاب',
        titleEn: 'Rate a Gaming Lounge',
        descriptionAr: 'شارك رأيك وتقييمك بعد انتهاء حجزك',
        descriptionEn: 'Share your review after completing a booking',
        pointsReward: 25,
        completedCount: 210,
        isActive: true,
      ),
    ];
  }

  @override
  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    try {
      await client.from('loyalty_tasks').update(data).eq('id', id);
    } catch (e) {
      AppLogger.warning('Update task note: $e');
    }
  }

  @override
  Future<List<LoyaltyLevelModel>> getLevels() async {
    try {
      final response =
          await client.from('loyalty_levels').select().order('min_points', ascending: true);
      final list = (response as List)
          .map((e) => LoyaltyLevelModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (e) {
      AppLogger.warning('Levels query fallback note: $e');
    }

    return const [
      LoyaltyLevelModel(
        id: 'lvl_bronze',
        nameAr: 'برونزي',
        nameEn: 'Bronze',
        minPoints: 0,
        multiplier: 1.0,
        userCount: 45,
        colorHex: '#CD7F32',
      ),
      LoyaltyLevelModel(
        id: 'lvl_silver',
        nameAr: 'فضي',
        nameEn: 'Silver',
        minPoints: 500,
        multiplier: 1.25,
        userCount: 28,
        colorHex: '#C0C0C0',
      ),
      LoyaltyLevelModel(
        id: 'lvl_gold',
        nameAr: 'ذهبي',
        nameEn: 'Gold',
        minPoints: 1500,
        multiplier: 1.5,
        userCount: 14,
        colorHex: '#FFD700',
      ),
      LoyaltyLevelModel(
        id: 'lvl_platinum',
        nameAr: 'بلاتيني',
        nameEn: 'Platinum',
        minPoints: 3500,
        multiplier: 2.0,
        userCount: 5,
        colorHex: '#E5E4E2',
      ),
    ];
  }

  @override
  Future<void> updateLevel(String id, Map<String, dynamic> data) async {
    try {
      await client.from('loyalty_levels').update(data).eq('id', id);
    } catch (e) {
      AppLogger.warning('Update level note: $e');
    }
  }

  @override
  Future<void> adjustUserPoints({
    required String userId,
    required int pointsDelta,
    required String reason,
  }) =>
      _transactionsHelper.adjustUserPoints(
        userId: userId,
        pointsDelta: pointsDelta,
        reason: reason,
      );

  @override
  Future<PaginatedResult<PointsTransactionModel>> getPointsTransactionsPage({
    int page = 1,
    int pageSize = 20,
  }) =>
      _transactionsHelper.getPointsTransactionsPage(
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<List<RedemptionOptionModel>> getRedemptionOptions() async {
    try {
      final response =
          await client.from('redemption_options').select().order('created_at', ascending: false);
      return (response as List)
          .map((e) => RedemptionOptionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      AppLogger.warning('Redemption options note: $e');
      return [];
    }
  }

  @override
  Future<void> createRedemptionOption(RedemptionOptionModel option) async {
    await client.from('redemption_options').insert(option.toJson());
  }

  @override
  Future<void> updateRedemptionOption(String id, Map<String, dynamic> data) async {
    await client.from('redemption_options').update(data).eq('id', id);
  }

  @override
  Future<void> deleteRedemptionOption(String id) async {
    await client.from('redemption_options').delete().eq('id', id);
  }
}
