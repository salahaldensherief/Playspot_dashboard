import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/tournament_audit_log_model.dart';
import '../models/tournament_match_model.dart';
import '../models/tournament_model.dart';
import '../models/tournament_participant_model.dart';
import '../models/tournament_prize_model.dart';
import 'tournament_audit_remote_helper.dart';
import 'tournament_match_remote_helper.dart';
import 'tournament_participant_remote_helper.dart';
import 'tournament_prize_remote_helper.dart';
import 'tournament_remote_data_source.dart';

class TournamentRemoteDataSourceImpl implements TournamentRemoteDataSource {
  final SupabaseClient client;
  final TournamentParticipantRemoteHelper _participantHelper;
  final TournamentMatchRemoteHelper _matchHelper;
  final TournamentAuditRemoteHelper _auditHelper;
  final TournamentPrizeRemoteHelper _prizeHelper;

  TournamentRemoteDataSourceImpl(this.client)
      : _participantHelper = TournamentParticipantRemoteHelper(client),
        _matchHelper = TournamentMatchRemoteHelper(client),
        _auditHelper = TournamentAuditRemoteHelper(client),
        _prizeHelper = TournamentPrizeRemoteHelper(client);

  @override
  Future<List<TournamentModel>> getTournaments({
    double? latitude,
    double? longitude,
    String? loungeId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = client.from('tournaments').select('''
        *,
        lounges(name),
        tournament_participants(id),
        tournament_prizes (
          id,
          tournament_id,
          placement,
          tournament_prize_rewards (*)
        )
      ''');

      if (loungeId != null && loungeId.trim().isNotEmpty) {
        query = query.eq('lounge_id', loungeId.trim());
      }
      if (status != null && status.trim().isNotEmpty) {
        query = query.eq('status', status.trim());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (response as List).map((json) {
        return TournamentModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      AppLogger.warning('getTournaments query error', e);
      var plainQuery = client.from('tournaments').select();
      if (loungeId != null && loungeId.trim().isNotEmpty) {
        plainQuery = plainQuery.eq('lounge_id', loungeId.trim());
      }
      if (status != null && status.trim().isNotEmpty) {
        plainQuery = plainQuery.eq('status', status.trim());
      }
      final response = await plainQuery
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (response as List).map((json) {
        return TournamentModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    }
  }

  @override
  Future<TournamentModel> createTournament(TournamentModel tournament) async {
    String? cityId = tournament.cityId;
    if ((cityId == null || cityId.isEmpty) && tournament.loungeId != null) {
      try {
        final loungeData = await client
            .from('lounges')
            .select('city_id')
            .eq('id', tournament.loungeId!)
            .maybeSingle();
        if (loungeData != null && loungeData['city_id'] != null) {
          cityId = loungeData['city_id'].toString();
        }
      } catch (e) {
        AppLogger.error('Failed to fetch city_id for lounge', e);
      }
    }

    if (cityId == null || cityId.isEmpty) {
      throw Exception('Lounge city is not configured');
    }

    try {
      final response = await client.rpc('create_tournament', params: {
        'p_lounge_id': tournament.loungeId,
        'p_city_id': cityId,
        'p_title_ar': tournament.titleAr ?? tournament.title,
        'p_title_en': tournament.titleEn ?? tournament.title,
        'p_game_name': tournament.gameTitle,
        'p_bracket_size': tournament.treeSize,
        'p_max_participants': tournament.maxPlayers,
        'p_entry_fee': tournament.entryFee,
        'p_registration_opens_at': tournament.registrationOpensAt?.toUtc().toIso8601String() ??
            tournament.startDate.toUtc().toIso8601String(),
        'p_registration_closes_at': (tournament.registrationClosesAt ?? tournament.registrationDeadline)
            .toUtc()
            .toIso8601String(),
        'p_tournament_starts_at': tournament.startDate.toUtc().toIso8601String(),
        'p_rules': tournament.rules,
        'p_banner_url': tournament.bannerUrl,
      });

      final createdData = response is List && response.isNotEmpty
          ? response.first
          : (response is Map ? response : null);
      if (createdData != null) {
        final model = TournamentModel.fromJson(Map<String, dynamic>.from(createdData));
        if (tournament.prizes.isNotEmpty) {
          final prizeModels = tournament.prizes.map((p) => TournamentPrizeModel.fromEntity(p)).toList();
          await saveTournamentPrizes(model.id, prizeModels);
        }
        return model;
      }
      throw Exception('Failed to create tournament via RPC: Empty response');
    } catch (e) {
      AppLogger.warning('create_tournament RPC error', e);
      rethrow;
    }
  }

  @override
  Future<TournamentModel> updateTournament(TournamentModel tournament) async {
    final payload = tournament.toJson();
    payload.remove('prizes');
    payload.remove('lounges');
    payload.remove('tournament_participants');

    final response = await client
        .from('tournaments')
        .update(payload)
        .eq('id', tournament.id)
        .select()
        .single();

    final updatedModel = TournamentModel.fromJson(Map<String, dynamic>.from(response));
    if (tournament.prizes.isNotEmpty) {
      final prizeModels = tournament.prizes.map((p) => TournamentPrizeModel.fromEntity(p)).toList();
      await saveTournamentPrizes(updatedModel.id, prizeModels);
    }
    return updatedModel;
  }

  @override
  Future<void> saveTournamentPrizes(String tournamentId, List<TournamentPrizeModel> prizes) =>
      _prizeHelper.saveTournamentPrizes(tournamentId, prizes);

  @override
  Future<void> publishTournament(String tournamentId) async {
    try {
      await client.rpc('publish_tournament', params: {'p_tournament_id': tournamentId, 'p_open': true});
    } catch (e) {
      AppLogger.warning('publish_tournament RPC error, fallback update', e);
      await client.from('tournaments').update({'status': 'registration_open'}).eq('id', tournamentId);
    }
  }

  @override
  Future<void> cancelTournament(String tournamentId, String reason) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw Exception('سبب إلغاء البطولة إجباري ولا يمكن أن يكون فارغاً.');
    }
    try {
      await client.rpc('cancel_tournament', params: {'p_tournament_id': tournamentId, 'p_reason': cleanReason});
    } catch (e) {
      AppLogger.warning('cancel_tournament RPC error, fallback update', e);
      await client.from('tournaments').update({'status': 'cancelled', 'cancellation_reason': cleanReason}).eq('id', tournamentId);
    }
  }

  @override
  Future<void> deleteDraftTournament(String tournamentId) async {
    try {
      final participantsRes = await client.from('tournament_participants').select('id').eq('tournament_id', tournamentId).limit(1);
      final matchesRes = await client.from('tournament_matches').select('id').eq('tournament_id', tournamentId).limit(1);
      if ((participantsRes as List).isNotEmpty || (matchesRes as List).isNotEmpty) {
        throw Exception('لا يمكن حذف المسودة لوجود مشاركين أو مباريات مسجلة فيها. يجب استخدام الإلغاء بدلاً من الحذف.');
      }
    } catch (e) {
      if (e.toString().contains('لا يمكن حذف المسودة')) rethrow;
    }

    try {
      await client.rpc('delete_draft_tournament', params: {'p_tournament_id': tournamentId});
    } catch (e) {
      AppLogger.warning('delete_draft_tournament RPC error, fallback delete', e);
      await client.from('tournaments').delete().eq('id', tournamentId).eq('status', 'draft');
    }
  }

  @override
  Future<void> deleteTournament(String tournamentId, {String? cancelReason}) async {
    final tData = await client.from('tournaments').select('status').eq('id', tournamentId).maybeSingle();
    if (tData == null) throw Exception('البطولة غير موجودة');
    final status = tData['status']?.toString() ?? 'draft';

    if (status == 'draft') {
      try {
        await deleteDraftTournament(tournamentId);
        return;
      } catch (e) {
        if (e.toString().contains('لا يمكن حذف المسودة')) {
          final reason = (cancelReason != null && cancelReason.trim().isNotEmpty)
              ? cancelReason.trim()
              : 'إلغاء مسودة مرتبطة بمشاركين أو مباريات';
          await cancelTournament(tournamentId, reason);
          return;
        }
        rethrow;
      }
    }

    final reason = (cancelReason != null && cancelReason.trim().isNotEmpty)
        ? cancelReason.trim()
        : 'إلغاء البطولة بقرار من الإدارة';
    await cancelTournament(tournamentId, reason);
  }

  // Delegated Participant Methods
  @override
  Future<List<TournamentParticipantModel>> getParticipants(String tournamentId) =>
      _participantHelper.getParticipants(tournamentId);

  @override
  Future<void> approvePayment(String participantId) =>
      _participantHelper.approvePayment(participantId);

  @override
  Future<void> rejectPayment(String participantId, String reason) =>
      _participantHelper.rejectPayment(participantId, reason);

  @override
  Future<void> recordCashPayment(String participantId) =>
      _participantHelper.recordCashPayment(participantId);

  @override
  Future<void> checkInParticipant(String participantId) =>
      _participantHelper.checkInParticipant(participantId);

  @override
  Future<void> withdrawParticipant(String participantId) =>
      _participantHelper.withdrawParticipant(participantId);

  @override
  Future<void> promoteWaitlist(String tournamentId) =>
      _participantHelper.promoteWaitlist(tournamentId);

  // Delegated Match Methods
  @override
  Future<List<TournamentMatchModel>> drawBracket(String tournamentId) =>
      _matchHelper.drawBracket(tournamentId);

  @override
  Future<List<TournamentMatchModel>> getMatches(String tournamentId) =>
      _matchHelper.getMatches(tournamentId);

  @override
  Future<void> startMatch(String matchId, {String? roomId}) =>
      _matchHelper.startMatch(matchId, roomId: roomId);

  @override
  Future<void> resolveDispute(
    String matchId, {
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  }) =>
      _matchHelper.resolveDispute(
        matchId,
        winnerId: winnerId,
        p1Score: p1Score,
        p2Score: p2Score,
        resolutionNotes: resolutionNotes,
      );

  @override
  Stream<List<TournamentMatchModel>> watchDisputedMatches(String tournamentId) =>
      _matchHelper.watchDisputedMatches(tournamentId);

  @override
  Future<void> completeTournament(String tournamentId) async {
    try {
      await client.rpc('complete_tournament', params: {'p_tournament_id': tournamentId});
    } catch (e) {
      AppLogger.warning('complete_tournament RPC error, fallback update', e);
      await client.from('tournaments').update({'status': 'completed'}).eq('id', tournamentId);
    }
  }

  @override
  Future<Map<String, dynamic>> awardPrizes(String tournamentId) =>
      _auditHelper.awardPrizes(tournamentId);

  @override
  Future<List<TournamentAuditLogModel>> getAuditLogs(String tournamentId) =>
      _auditHelper.getAuditLogs(tournamentId);

  @override
  Future<PaginatedResult<TournamentAuditLogModel>> getTournamentAuditLogsPage({
    required String tournamentId,
    int page = 1,
    int pageSize = 50,
  }) =>
      _auditHelper.getTournamentAuditLogsPage(
        tournamentId: tournamentId,
        page: page,
        pageSize: pageSize,
      );
}
