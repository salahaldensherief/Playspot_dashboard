import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loyalty_stats_model.dart';
import '../models/referral_model.dart';

class LoyaltyStatsRemoteHelper {
  final SupabaseClient client;
  LoyaltyStatsRemoteHelper(this.client);

  Future<LoyaltyStatsModel> getLoyaltyStats({
    DateTime? startDate,
    DateTime? endDate,
    String? levelId,
    String? referralStatus,
    String? userId,
  }) async {
    final response = await client.rpc(
      'get_loyalty_dashboard_stats',
      params: {
        if (startDate != null)
          'p_start_date': startDate.toUtc().toIso8601String(),
        if (endDate != null) 'p_end_date': endDate.toUtc().toIso8601String(),
        if (levelId != null && levelId.isNotEmpty) 'p_level_id': levelId,
        if (referralStatus != null &&
            referralStatus.isNotEmpty &&
            referralStatus != 'all')
          'p_referral_status': referralStatus,
        if (userId != null && userId.trim().isNotEmpty)
          'p_user_query': userId.trim(),
      },
    );
    if (response is! Map)
      throw const FormatException('Invalid loyalty aggregate response');
    // Only the server can supply complete aggregates. A missing contract is an error.
    return LoyaltyStatsModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<List<ReferralModel>> getReferrals({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? userId,
  }) async {
    final response = await client.rpc(
      'get_loyalty_referrals',
      params: {
        if (startDate != null)
          'p_start_date': startDate.toUtc().toIso8601String(),
        if (endDate != null) 'p_end_date': endDate.toUtc().toIso8601String(),
        if (status != null && status.isNotEmpty && status != 'all')
          'p_status': status,
        if (userId != null && userId.trim().isNotEmpty)
          'p_user_query': userId.trim(),
      },
    );

    if (response is! List) {
      throw const FormatException('Invalid loyalty referrals response');
    }

    return response
        .map(
          (item) => ReferralModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
