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
    await client.rpc(
      'update_user_points',
      params: buildAdjustmentParams(
        userId: userId,
        pointsDelta: pointsDelta,
        reason: reason,
      ),
    );
  }

  static Map<String, dynamic> buildAdjustmentParams({
    required String userId,
    required int pointsDelta,
    required String reason,
  }) {
    return {
      'p_user_id': userId,
      'p_points_change': pointsDelta,
      'p_reason': reason.trim(),
    };
  }

  Future<PaginatedResult<PointsTransactionModel>> getPointsTransactionsPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    final clampedPageSize = pageSize.clamp(1, 100);
    final validPage = page < 1 ? 1 : page;

    try {
      final response = await client.rpc(
        'get_points_transactions_page',
        params: {'p_page': validPage, 'p_page_size': clampedPageSize},
      );

      return PaginatedResult.fromRpcResponse<PointsTransactionModel>(
        response,
        mapper: (json) => PointsTransactionModel.fromJson(json),
        requestedPage: validPage,
        requestedPageSize: clampedPageSize,
      );
    } catch (e) {
      AppLogger.warning(
        'get_points_transactions_page RPC failed ($e), falling back to query',
      );
      try {
        final userId = client.auth.currentUser?.id;
        if (userId == null || userId.isEmpty) {
          return PaginatedResult.empty(
            requestedPage: validPage,
            requestedPageSize: clampedPageSize,
          );
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
            .map(
              (e) => PointsTransactionModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();

        return PaginatedResult(
          items: list,
          totalCount: list.length,
          page: validPage,
          pageSize: clampedPageSize,
        );
      } catch (e2) {
        AppLogger.error('Fallback query for points_transactions failed: $e2');
        return PaginatedResult.empty(
          requestedPage: validPage,
          requestedPageSize: clampedPageSize,
        );
      }
    }
  }
}
