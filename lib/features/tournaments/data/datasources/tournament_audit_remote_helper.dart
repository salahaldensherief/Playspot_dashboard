import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import '../models/tournament_audit_log_model.dart';

class TournamentAuditRemoteHelper {
  final SupabaseClient client;

  const TournamentAuditRemoteHelper(this.client);

  Future<Map<String, dynamic>> awardPrizes(String tournamentId) async {
    try {
      final response = await client.rpc('award_tournament_prizes', params: {'p_tournament_id': tournamentId});
      if (response != null && response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'status': 'success'};
    } catch (e) {
      AppLogger.warning('award_tournament_prizes RPC error', e);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<List<TournamentAuditLogModel>> getAuditLogs(String tournamentId) async {
    try {
      final response = await client
          .from('tournament_audit_logs')
          .select('*, profiles:performed_by(full_name)')
          .eq('tournament_id', tournamentId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        return TournamentAuditLogModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      AppLogger.warning('getAuditLogs error', e);
      final plainResponse = await client
          .from('tournament_audit_logs')
          .select()
          .eq('tournament_id', tournamentId)
          .order('created_at', ascending: false);

      return (plainResponse as List).map((json) {
        return TournamentAuditLogModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    }
  }

  Future<PaginatedResult<TournamentAuditLogModel>> getTournamentAuditLogsPage({
    required String tournamentId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final cleanTournamentId = tournamentId.trim();
    if (cleanTournamentId.isEmpty) {
      return PaginatedResult.empty(requestedPage: page, requestedPageSize: pageSize);
    }

    final clampedPageSize = pageSize.clamp(1, 100);
    final validPage = page < 1 ? 1 : page;

    try {
      final response = await client.rpc('get_tournament_audit_logs_page', params: {
        'p_tournament_id': cleanTournamentId,
        'p_page': validPage,
        'p_page_size': clampedPageSize,
      });

      return PaginatedResult.fromRpcResponse<TournamentAuditLogModel>(
        response,
        mapper: (json) => TournamentAuditLogModel.fromJson(json),
        requestedPage: validPage,
        requestedPageSize: clampedPageSize,
      );
    } catch (e) {
      AppLogger.warning('get_tournament_audit_logs_page RPC error, falling back', e);
      final fallbackList = await getAuditLogs(cleanTournamentId);
      return PaginatedResult(
        items: fallbackList,
        totalCount: fallbackList.length,
        page: validPage,
        pageSize: clampedPageSize,
      );
    }
  }
}
