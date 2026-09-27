import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../../../core/utils/paginated_result.dart';
import '../models/points_transaction_model.dart';

class LoyaltyTransactionsRemoteHelper {
  final SupabaseClient client;

  LoyaltyTransactionsRemoteHelper(this.client);

  Future<void> adjustUserPoints({
    required String userId,
    required int pointsDelta,
    required String reason,
  }) async {
    try {
      await client.rpc('award_points', params: {
        'p_user_id': userId,
        'p_points_delta': pointsDelta,
        'p_source_type': 'admin_adjust',
        'p_source_id': null,
        'p_reason': reason,
        'p_metadata': {'adjusted_by_admin': true},
        'p_idempotency_key': 'admin_adjust_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      });
      return;
    } catch (e) {
      AppLogger.warning('award_points RPC failed, executing fallback insert: $e');
    }

    try {
      await client.from('points_transactions').insert({
        'user_id': userId,
        'points_delta': pointsDelta,
        'type': 'admin_adjust',
        'source_type': 'admin_adjust',
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.warning('Log points transaction fallback note: $e');
    }

    try {
      final userRes =
          await client.from('profiles').select('points_balance').eq('id', userId).maybeSingle();
      final currentBalance = (userRes?['points_balance'] as num?)?.toInt() ?? 0;
      final newBalance = currentBalance + pointsDelta;

      await client.from('profiles').update({
        'points_balance': newBalance < 0 ? 0 : newBalance,
      }).eq('id', userId);
    } catch (e) {
      AppLogger.error('Error updating user points in profiles: $e');
    }
  }

  Future<PaginatedResult<PointsTransactionModel>> getPointsTransactionsPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    final clampedPageSize = pageSize.clamp(1, 100);
    final validPage = page < 1 ? 1 : page;

    try {
      final response = await client.rpc('get_points_transactions_page', params: {
        'p_page': validPage,
        'p_page_size': clampedPageSize,
      });

      return PaginatedResult.fromRpcResponse<PointsTransactionModel>(
        response,
        mapper: (json) => PointsTransactionModel.fromJson(json),
        requestedPage: validPage,
        requestedPageSize: clampedPageSize,
      );
    } catch (e) {
      AppLogger.warning('get_points_transactions_page RPC failed ($e), falling back to query');
      try {
        final userId = client.auth.currentUser?.id;
        if (userId == null || userId.isEmpty) {
          return PaginatedResult.empty(requestedPage: validPage, requestedPageSize: clampedPageSize);
        }

        final from = (validPage - 1) * clampedPageSize;
        final to = from + clampedPageSize - 1;

        final queryRes = await client
            .from('points_transactions')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .range(from, to);

        final list = (queryRes as List)
            .map((e) => PointsTransactionModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        return PaginatedResult(
          items: list,
          totalCount: list.length,
          page: validPage,
          pageSize: clampedPageSize,
        );
      } catch (e2) {
        AppLogger.error('Fallback query for points_transactions failed: $e2');
        return PaginatedResult.empty(requestedPage: validPage, requestedPageSize: clampedPageSize);
      }
    }
  }
}
