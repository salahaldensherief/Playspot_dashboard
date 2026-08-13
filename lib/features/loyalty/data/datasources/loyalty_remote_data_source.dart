import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loyalty_stats_model.dart';
import '../../../marketing/data/models/redemption_option_model.dart';

abstract class LoyaltyRemoteDataSource {
  Future<LoyaltyStatsModel> getLoyaltyStats();
  Future<List<RedemptionOptionModel>> getRedemptionOptions();
  Future<void> createRedemptionOption(RedemptionOptionModel option);
  Future<void> updateRedemptionOption(String id, Map<String, dynamic> data);
  Future<void> deleteRedemptionOption(String id);
}

class LoyaltyRemoteDataSourceImpl implements LoyaltyRemoteDataSource {
  final SupabaseClient client;
  LoyaltyRemoteDataSourceImpl(this.client);

  @override
  Future<LoyaltyStatsModel> getLoyaltyStats() async {
    try {
      final response = await client.rpc('get_voucher_stats');
      return LoyaltyStatsModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      // Fallback if RPC is not created yet
      print('Loyalty Stats Alert: RPC get_voucher_stats failed, using default values. Error: $e');
      return LoyaltyStatsModel(
        totalVouchersIssued: 0,
        totalVouchersUsed: 0,
        totalVouchersActive: 0,
        totalDiscountValueUsed: 0.0,
      );
    }
  }

  @override
  Future<List<RedemptionOptionModel>> getRedemptionOptions() async {
    final response = await client.from('redemption_options').select().order('created_at', ascending: false);
    return (response as List).map((e) => RedemptionOptionModel.fromJson(Map<String, dynamic>.from(e))).toList();
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
