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
        if (startDate != null) 'p_start_date': startDate.toIso8601String(),
        if (endDate != null) 'p_end_date': endDate.toIso8601String(),
        if (levelId != null && levelId.isNotEmpty) 'p_level_id': levelId,
        if (referralStatus != null &&
            referralStatus.isNotEmpty &&
            referralStatus != 'all')
          'p_referral_status': referralStatus,
        if (userId != null && userId.isNotEmpty) 'p_user_id': userId,
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
    var query = client
        .from('referrals')
        .select('id,referrer_id,referred_id,status,reward_claimed,created_at');
    if (startDate != null)
      query = query.gte('created_at', startDate.toIso8601String());
    if (endDate != null)
      query = query.lte('created_at', endDate.toIso8601String());
    if (status != null && status.isNotEmpty && status != 'all')
      query = query.eq('status', status);
    if (userId != null && userId.isNotEmpty)
      query = query.or('referrer_id.eq.$userId,referred_id.eq.$userId');
    final response = await query.order('created_at', ascending: false);
    if (response.isEmpty) return [];
    final ids = <String>{
      for (final row in response) ...[
        row['referrer_id'].toString(),
        row['referred_id'].toString(),
      ],
    };
    // Referrals reference auth users; do not invent a foreign key to profiles.
    final profiles = await client
        .from('profiles')
        .select('id,full_name,email')
        .inFilter('id', ids.toList());
    final byId = {for (final row in profiles) row['id'].toString(): row};
    return [
      for (final row in response)
        ReferralModel.fromJson({
          ...row,
          'referrer': byId[row['referrer_id'].toString()],
          'referred': byId[row['referred_id'].toString()],
        }),
    ];
  }
}
