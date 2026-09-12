import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import '../models/tournament_audit_log_model.dart';
import '../models/tournament_match_model.dart';
import '../models/tournament_model.dart';
import '../models/tournament_participant_model.dart';

abstract class TournamentRemoteDataSource {
  Future<List<TournamentModel>> getTournaments({String? loungeId, String? status});
  Future<TournamentModel> createTournament(TournamentModel tournament);
  Future<TournamentModel> updateTournament(TournamentModel tournament);
  Future<void> publishTournament(String tournamentId);
  Future<void> cancelTournament(String tournamentId, String reason);
  Future<void> deleteDraftTournament(String tournamentId);

  Future<List<TournamentParticipantModel>> getParticipants(String tournamentId);
  Future<void> approvePayment(String participantId);
  Future<void> rejectPayment(String participantId, String reason);
  Future<void> recordCashPayment(String participantId);
  Future<void> checkInParticipant(String participantId);

  Future<List<TournamentMatchModel>> drawBracket(String tournamentId);
  Future<List<TournamentMatchModel>> getMatches(String tournamentId);
  Future<void> startMatch(String matchId, {String? roomId});
  Future<void> resolveDispute(
    String matchId, {
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  });

  Future<void> completeTournament(String tournamentId);
  Future<Map<String, dynamic>> awardPrizes(String tournamentId);
  Future<List<TournamentAuditLogModel>> getAuditLogs(String tournamentId);
  Future<PaginatedResult<TournamentAuditLogModel>> getTournamentAuditLogsPage({
    required String tournamentId,
    int page = 1,
    int pageSize = 50,
  });

  Stream<List<TournamentMatchModel>> watchDisputedMatches(String tournamentId);
}

class TournamentRemoteDataSourceImpl implements TournamentRemoteDataSource {
  final SupabaseClient client;
  RealtimeChannel? _disputesChannel;

  TournamentRemoteDataSourceImpl(this.client);

  @override
  Future<List<TournamentModel>> getTournaments({String? loungeId, String? status}) async {
    try {
      var query = client.from('tournaments').select('''
        *,
        lounges(name),
        tournament_participants(id)
      ''');

      if (loungeId != null && loungeId.trim().isNotEmpty) {
        query = query.eq('lounge_id', loungeId.trim());
      }
      if (status != null && status.trim().isNotEmpty) {
        query = query.eq('status', status.trim());
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) {
        return TournamentModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] getTournaments query error: $e');
      // Fallback plain query without joins
      var plainQuery = client.from('tournaments').select();
      if (loungeId != null && loungeId.trim().isNotEmpty) {
        plainQuery = plainQuery.eq('lounge_id', loungeId.trim());
      }
      if (status != null && status.trim().isNotEmpty) {
        plainQuery = plainQuery.eq('status', status.trim());
      }
      final response = await plainQuery.order('created_at', ascending: false);
      return (response as List).map((json) {
        return TournamentModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    }
  }

  @override
  Future<TournamentModel> createTournament(TournamentModel tournament) async {
    try {
      final response = await client.rpc('create_tournament', params: {
        'p_lounge_id': tournament.loungeId,
        'p_city_id': tournament.cityId,
        'p_title': tournament.title,
        'p_title_ar': tournament.titleAr ?? tournament.title,
        'p_title_en': tournament.titleEn ?? tournament.title,
        'p_description_ar': tournament.descriptionAr ?? tournament.rules,
        'p_description_en': tournament.descriptionEn ?? tournament.rules,
        'p_game_title': tournament.gameTitle,
        'p_game_name': tournament.gameTitle,
        'p_banner_url': tournament.bannerUrl,
        'p_tree_size': tournament.treeSize,
        'p_bracket_size': tournament.treeSize,
        'p_entry_fee': tournament.entryFee,
        'p_prize_pool': tournament.prizePool,
        'p_start_date': tournament.startDate.toIso8601String(),
        'p_end_date': tournament.endDate.toIso8601String(),
        'p_registration_deadline': tournament.registrationDeadline.toIso8601String(),
        if (tournament.registrationOpensAt != null)
          'p_registration_opens_at': tournament.registrationOpensAt!.toIso8601String(),
        'p_registration_closes_at':
            (tournament.registrationClosesAt ?? tournament.registrationDeadline).toIso8601String(),
        'p_payment_deadline_minutes': tournament.paymentDeadlineMinutes,
        if (tournament.checkInOpensAt != null)
          'p_check_in_opens_at': tournament.checkInOpensAt!.toIso8601String(),
        if (tournament.checkInClosesAt != null)
          'p_check_in_closes_at': tournament.checkInClosesAt!.toIso8601String(),
        'p_tournament_starts_at':
            (tournament.tournamentStartsAt ?? tournament.startDate).toIso8601String(),
        'p_min_players': tournament.minPlayers,
        'p_max_players': tournament.maxPlayers,
        'p_max_participants': tournament.maxPlayers,
        'p_rules': tournament.rules,
      });

      if (response != null && response is Map) {
        return TournamentModel.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] create_tournament RPC error: $e, falling back to direct insert');
    }

    final insertMap = tournament.toJson();
    final inserted = await client.from('tournaments').insert(insertMap).select().single();
    return TournamentModel.fromJson(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<TournamentModel> updateTournament(TournamentModel tournament) async {
    try {
      final response = await client.rpc('update_tournament', params: {
        'p_tournament_id': tournament.id,
        'p_title': tournament.title,
        'p_game_title': tournament.gameTitle,
        'p_banner_url': tournament.bannerUrl,
        'p_tree_size': tournament.treeSize,
        'p_entry_fee': tournament.entryFee,
        'p_prize_pool': tournament.prizePool,
        'p_start_date': tournament.startDate.toIso8601String(),
        'p_end_date': tournament.endDate.toIso8601String(),
        'p_registration_deadline': tournament.registrationDeadline.toIso8601String(),
        'p_min_players': tournament.minPlayers,
        'p_max_players': tournament.maxPlayers,
        'p_rules': tournament.rules,
      });

      if (response != null && response is Map) {
        return TournamentModel.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] update_tournament RPC error: $e, falling back to direct update');
    }

    final updateMap = tournament.toJson();
    final updated = await client
        .from('tournaments')
        .update(updateMap)
        .eq('id', tournament.id)
        .select()
        .single();
    return TournamentModel.fromJson(Map<String, dynamic>.from(updated));
  }

  @override
  Future<void> publishTournament(String tournamentId) async {
    try {
      await client.rpc('publish_tournament', params: {'p_tournament_id': tournamentId});
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] publish_tournament RPC error: $e, fallback update');
      await client
          .from('tournaments')
          .update({'status': 'published'})
          .eq('id', tournamentId);
    }
  }

  @override
  Future<void> cancelTournament(String tournamentId, String reason) async {
    try {
      await client.rpc('cancel_tournament', params: {
        'p_tournament_id': tournamentId,
        'p_reason': reason,
      });
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] cancel_tournament RPC error: $e, fallback update');
      await client
          .from('tournaments')
          .update({'status': 'cancelled'})
          .eq('id', tournamentId);
    }
  }

  @override
  Future<void> deleteDraftTournament(String tournamentId) async {
    try {
      await client.rpc('delete_draft_tournament', params: {'p_tournament_id': tournamentId});
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] delete_draft_tournament RPC error: $e, fallback delete');
      await client.from('tournaments').delete().eq('id', tournamentId).eq('status', 'draft');
    }
  }

  @override
  Future<List<TournamentParticipantModel>> getParticipants(String tournamentId) async {
    try {
      final response = await client
          .from('tournament_participants')
          .select('''
            *,
            profiles(full_name, phone, email)
          ''')
          .eq('tournament_id', tournamentId)
          .order('registered_at', ascending: false);

      final list = (response as List).map((json) {
        return TournamentParticipantModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();

      // Resolve signed URLs for receipts if available
      final resultWithSignedUrls = await Future.wait(list.map((p) async {
        if (p.receiptPath != null && p.receiptPath!.isNotEmpty) {
          try {
            final signedUrl = await client.storage
                .from('tournament-receipts')
                .createSignedUrl(p.receiptPath!, 3600);
            return p.copyWithSignedUrl(signedUrl);
          } catch (storageErr) {
            debugPrint('⚠️ [TOURNAMENTS_REMOTE] Failed to generate signed URL for receipt: $storageErr');
          }
        }
        return p;
      }));

      return resultWithSignedUrls;
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] getParticipants error: $e');
      final plainResponse = await client
          .from('tournament_participants')
          .select()
          .eq('tournament_id', tournamentId)
          .order('registered_at', ascending: false);

      return (plainResponse as List).map((json) {
        return TournamentParticipantModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    }
  }

  @override
  Future<void> approvePayment(String participantId) async {
    try {
      await client.rpc('approve_tournament_payment', params: {'p_participant_id': participantId});
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] approve_tournament_payment RPC error: $e, fallback update');
      await client
          .from('tournament_participants')
          .update({'payment_status': 'approved'})
          .eq('id', participantId);
    }
  }

  @override
  Future<void> rejectPayment(String participantId, String reason) async {
    try {
      await client.rpc('reject_tournament_payment', params: {
        'p_participant_id': participantId,
        'p_reason': reason,
      });
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] reject_tournament_payment RPC error: $e, fallback update');
      await client.from('tournament_participants').update({
        'payment_status': 'rejected',
        'rejection_reason': reason,
      }).eq('id', participantId);
    }
  }

  @override
  Future<void> recordCashPayment(String participantId) async {
    try {
      await client.rpc('record_cash_tournament_payment', params: {'p_participant_id': participantId});
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] record_cash_tournament_payment RPC error: $e, fallback update');
      await client
          .from('tournament_participants')
          .update({'payment_status': 'approved'})
          .eq('id', participantId);
    }
  }

  @override
  Future<void> checkInParticipant(String participantId) async {
    try {
      await client.rpc('check_in_tournament_participant', params: {'p_participant_id': participantId});
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] check_in_tournament_participant RPC error: $e, fallback update');
      await client.from('tournament_participants').update({
        'is_checked_in': true,
        'checked_in_at': DateTime.now().toIso8601String(),
      }).eq('id', participantId);
    }
  }

  @override
  Future<List<TournamentMatchModel>> drawBracket(String tournamentId) async {
    try {
      final response = await client.rpc('draw_tournament_bracket', params: {
        'p_tournament_id': tournamentId,
      });

      if (response != null && response is List) {
        return (response as List).map((json) {
          return TournamentMatchModel.fromJson(Map<String, dynamic>.from(json));
        }).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] draw_tournament_bracket RPC error: $e');
    }

    return getMatches(tournamentId);
  }

  @override
  Future<List<TournamentMatchModel>> getMatches(String tournamentId) async {
    try {
      final response = await client
          .from('tournament_matches')
          .select('''
            *,
            p1_profile:profiles!tournament_matches_player1_id_fkey(full_name),
            p2_profile:profiles!tournament_matches_player2_id_fkey(full_name),
            rooms(name)
          ''')
          .eq('tournament_id', tournamentId)
          .order('round', ascending: true)
          .order('match_number', ascending: true);

      return (response as List).map((json) {
        return TournamentMatchModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] getMatches join query error: $e');
      final plainResponse = await client
          .from('tournament_matches')
          .select()
          .eq('tournament_id', tournamentId)
          .order('round', ascending: true)
          .order('match_number', ascending: true);

      return (plainResponse as List).map((json) {
        return TournamentMatchModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    }
  }

  @override
  Future<void> startMatch(String matchId, {String? roomId}) async {
    try {
      await client.rpc('start_tournament_match', params: {
        'p_match_id': matchId,
        'p_room_id': roomId,
      });
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] start_tournament_match RPC error: $e, fallback update');
      await client.from('tournament_matches').update({
        'status': 'in_progress',
        if (roomId != null) 'room_id': roomId,
        'started_at': DateTime.now().toIso8601String(),
      }).eq('id', matchId);
    }
  }

  @override
  Future<void> resolveDispute(
    String matchId, {
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  }) async {
    try {
      await client.rpc('resolve_tournament_dispute', params: {
        'p_match_id': matchId,
        'p_winner_id': winnerId,
        'p_p1_score': p1Score,
        'p_p2_score': p2Score,
        'p_resolution_notes': resolutionNotes,
      });
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] resolve_tournament_dispute RPC error: $e, fallback update');
      await client.from('tournament_matches').update({
        'status': 'completed',
        'winner_id': winnerId,
        'player1_score': p1Score,
        'player2_score': p2Score,
        'resolution_notes': resolutionNotes,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', matchId);
    }
  }

  @override
  Future<void> completeTournament(String tournamentId) async {
    try {
      await client.rpc('complete_tournament', params: {'p_tournament_id': tournamentId});
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] complete_tournament RPC error: $e, fallback update');
      await client
          .from('tournaments')
          .update({'status': 'completed'})
          .eq('id', tournamentId);
    }
  }

  @override
  Future<Map<String, dynamic>> awardPrizes(String tournamentId) async {
    try {
      final response = await client.rpc('award_tournament_prizes', params: {
        'p_tournament_id': tournamentId,
      });
      if (response != null && response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'status': 'success'};
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] award_tournament_prizes RPC error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  @override
  Future<List<TournamentAuditLogModel>> getAuditLogs(String tournamentId) async {
    try {
      final response = await client
          .from('tournament_audit_logs')
          .select('''
            *,
            profiles:performed_by(full_name)
          ''')
          .eq('tournament_id', tournamentId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        return TournamentAuditLogModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] getAuditLogs error: $e');
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

  @override
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
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] get_tournament_audit_logs_page RPC error ($e), falling back');
      final fallbackList = await getAuditLogs(cleanTournamentId);
      return PaginatedResult(
        items: fallbackList,
        totalCount: fallbackList.length,
        page: validPage,
        pageSize: clampedPageSize,
      );
    }
  }

  @override
  Stream<List<TournamentMatchModel>> watchDisputedMatches(String tournamentId) {
    if (_disputesChannel != null) {
      client.removeChannel(_disputesChannel!);
    }

    final controller = StreamController<List<TournamentMatchModel>>();

    // Initial fetch
    getMatches(tournamentId).then((allMatches) {
      if (!controller.isClosed) {
        controller.add(allMatches.where((m) => m.isDisputed).toList());
      }
    }).catchError((err) {
      if (!controller.isClosed) {
        controller.addError(err);
      }
    });

    _disputesChannel = client
        .channel('public:tournament_matches:disputed:$tournamentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tournament_matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournament_id',
            value: tournamentId,
          ),
          callback: (payload) async {
            try {
              final newStatus = payload.newRecord['status'] as String?;
              final oldStatus = payload.oldRecord['status'] as String?;

              // Only re-fetch matches if the payload pertains to a disputed match
              // or a match whose dispute status was just changed/resolved.
              if (newStatus == 'disputed' || oldStatus == 'disputed') {
                final freshMatches = await getMatches(tournamentId);
                if (!controller.isClosed) {
                  controller.add(freshMatches.where((m) => m.isDisputed).toList());
                }
              }
            } catch (e) {
              debugPrint('⚠️ [TOURNAMENTS_REMOTE] Realtime update fetch error: $e');
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      if (_disputesChannel != null) {
        client.removeChannel(_disputesChannel!);
        _disputesChannel = null;
      }
    };

    return controller.stream;
  }
}
