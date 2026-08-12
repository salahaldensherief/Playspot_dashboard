import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payout_model.dart';

abstract class PayoutRemoteDataSource {
  Future<List<PendingPayoutOverviewModel>> getPendingPayoutsOverview();
  Future<Map<String, dynamic>> createPayout({
    required String loungeId,
    required String periodStart,
    required String periodEnd,
  });
  Future<void> markPayoutPaid({
    required String payoutId,
    String? notes,
  });
  Future<List<PayoutModel>> getPayoutsByLounge(String loungeId);
}

class PayoutRemoteDataSourceImpl implements PayoutRemoteDataSource {
  final SupabaseClient _supabase;

  PayoutRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<PendingPayoutOverviewModel>> getPendingPayoutsOverview() async {
    final response = await _supabase.rpc('get_pending_payouts_overview');
    return (response as List).map((e) => PendingPayoutOverviewModel.fromJson(e)).toList();
  }

  @override
  Future<Map<String, dynamic>> createPayout({
    required String loungeId,
    required String periodStart,
    required String periodEnd,
  }) async {
    final response = await _supabase.rpc('create_payout', params: {
      'p_lounge_id': loungeId,
      'p_period_start': periodStart,
      'p_period_end': periodEnd,
    });
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> markPayoutPaid({
    required String payoutId,
    String? notes,
  }) async {
    await _supabase.rpc('mark_payout_paid', params: {
      'p_payout_id': payoutId,
      'p_notes': notes,
    });
  }

  @override
  Future<List<PayoutModel>> getPayoutsByLounge(String loungeId) async {
    final response = await _supabase
        .from('payouts')
        .select()
        .eq('lounge_id', loungeId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => PayoutModel.fromJson(e)).toList();
  }
}
