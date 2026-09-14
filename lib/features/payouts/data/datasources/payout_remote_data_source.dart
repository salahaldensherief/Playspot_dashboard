import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payout_model.dart';

abstract class PayoutRemoteDataSource {
  Future<List<PendingPayoutOverviewModel>> getPendingPayoutsOverview();
  Future<List<PayoutModel>> getAllPayouts();
  Future<Map<String, dynamic>> createPayout({
    required String loungeId,
    required String periodStart,
    required String periodEnd,
  });
  Future<void> approvePayout({
    required String payoutId,
    String? notes,
  });
  Future<void> startPayoutProcessing({
    required String payoutId,
  });
  Future<void> completePayout({
    required String payoutId,
    required String transferMethod,
    required String transferReference,
    String? receiptUrl,
    String? notes,
  });
  Future<void> markPayoutPaid({
    required String payoutId,
    String? notes,
  });
  Future<void> failPayout({
    required String payoutId,
    required String reason,
  });
  Future<void> cancelPayout({
    required String payoutId,
    required String reason,
  });
  Future<void> resolvePayoutReview({
    required String payoutId,
    required String resolution, // 'approve' or 'cancel'
    required String reason,
  });
  Future<Map<String, dynamic>> getPayoutDetails({
    required String payoutId,
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
  Future<List<PayoutModel>> getAllPayouts() async {
    final response = await _supabase
        .from('payouts')
        .select('*, lounges(name)')
        .order('created_at', ascending: false);
    return (response as List).map((e) => PayoutModel.fromJson(e)).toList();
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
  Future<void> approvePayout({
    required String payoutId,
    String? notes,
  }) async {
    await _supabase.rpc('approve_payout', params: {
      'p_payout_id': payoutId,
      'p_notes': notes,
    });
  }

  @override
  Future<void> startPayoutProcessing({
    required String payoutId,
  }) async {
    await _supabase.rpc('start_payout_processing', params: {
      'p_payout_id': payoutId,
    });
  }

  @override
  Future<void> completePayout({
    required String payoutId,
    required String transferMethod,
    required String transferReference,
    String? receiptUrl,
    String? notes,
  }) async {
    await _supabase.rpc('complete_payout', params: {
      'p_payout_id': payoutId,
      'p_transfer_method': transferMethod,
      'p_transfer_reference': transferReference,
      'p_receipt_url': receiptUrl,
      'p_notes': notes,
    });
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
  Future<void> failPayout({
    required String payoutId,
    required String reason,
  }) async {
    await _supabase.rpc('fail_payout', params: {
      'p_payout_id': payoutId,
      'p_reason': reason,
    });
  }

  @override
  Future<void> cancelPayout({
    required String payoutId,
    required String reason,
  }) async {
    await _supabase.rpc('cancel_payout', params: {
      'p_payout_id': payoutId,
      'p_reason': reason,
    });
  }

  @override
  Future<void> resolvePayoutReview({
    required String payoutId,
    required String resolution,
    required String reason,
  }) async {
    await _supabase.rpc('resolve_payout_review', params: {
      'p_payout_id': payoutId,
      'p_resolution': resolution,
      'p_reason': reason,
    });
  }

  @override
  Future<Map<String, dynamic>> getPayoutDetails({
    required String payoutId,
  }) async {
    final response = await _supabase.rpc('get_payout_details', params: {
      'p_payout_id': payoutId,
    });
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<PayoutModel>> getPayoutsByLounge(String loungeId) async {
    final response = await _supabase
        .from('payouts')
        .select('*, lounges(name)')
        .eq('lounge_id', loungeId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => PayoutModel.fromJson(e)).toList();
  }
}
