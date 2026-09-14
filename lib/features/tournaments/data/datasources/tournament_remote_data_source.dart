import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import '../models/tournament_audit_log_model.dart';
import '../models/tournament_match_model.dart';
import '../models/tournament_model.dart';
import '../models/tournament_participant_model.dart';

abstract class TournamentRemoteDataSource {
  Future<List<TournamentModel>> getTournaments({
    String? loungeId,
    String? status,
    double? latitude,
    double? longitude,
  });
  Future<TournamentModel> createTournament(TournamentModel tournament);
  Future<TournamentModel> updateTournament(TournamentModel tournament);
  Future<void> publishTournament(String tournamentId);
  Future<void> cancelTournament(String tournamentId, String reason);
  Future<void> deleteDraftTournament(String tournamentId);

  Future<List<TournamentParticipantModel>> getParticipants(String tournamentId);
  Future<void> approvePayment(String participantId);
  Future<void> rejectPayment(String participantId, String reason);
  Future<void> recordCashPayment(String participantId);
  Future<void> promoteWaitlist(String tournamentId);
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
  Future<List<TournamentModel>> getTournaments({
    String? loungeId,
    String? status,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final rpcParams = <String, dynamic>{
        'p_latitude': latitude,
        'p_longitude': longitude,
      };

      debugPrint('🔵 [TOURNAMENTS_REMOTE] Calling get_visible_tournaments RPC with params: $rpcParams');
      final response = await client.rpc('get_visible_tournaments', params: rpcParams);

      if (response != null && response is List) {
        var list = (response as List).map((json) {
          return TournamentModel.fromJson(Map<String, dynamic>.from(json));
        }).toList();

        if (loungeId != null && loungeId.trim().isNotEmpty) {
          list = list.where((t) => t.loungeId == loungeId.trim()).toList();
        }
        if (status != null && status.trim().isNotEmpty) {
          list = list.where((t) => t.status.toDbString() == status.trim() || t.status.name == status.trim()).toList();
        }
        return list;
      }
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] get_visible_tournaments RPC query error: $e');
    }

    // Fallback plain query without joins
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
  }

  bool _isValidUuid(String? str) {
    if (str == null || str.trim().isEmpty) return false;
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(str.trim());
  }

  @override
  Future<TournamentModel> createTournament(TournamentModel tournament) async {
    String? createdId;

    // Resolve a valid city_id UUID to satisfy NOT NULL constraint on tournaments.city_id
    String? resolvedCityId = tournament.cityId;
    if (resolvedCityId == null || !_isValidUuid(resolvedCityId)) {
      try {
        if (tournament.loungeId != null && _isValidUuid(tournament.loungeId)) {
          final loungeRes = await client.from('lounges').select('city').eq('id', tournament.loungeId!).maybeSingle();
          if (loungeRes != null && loungeRes['city'] != null) {
            final cityName = loungeRes['city'].toString().trim();
            if (cityName.isNotEmpty) {
              final cityRes = await client
                  .from('cities')
                  .select('id')
                  .or('name_ar.ilike.%$cityName%,name_en.ilike.%$cityName%')
                  .limit(1)
                  .maybeSingle();
              if (cityRes != null && cityRes['id'] != null) {
                resolvedCityId = cityRes['id'].toString();
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [TOURNAMENTS_REMOTE] Failed to lookup city by lounge city name: $e');
      }

      if (resolvedCityId == null || !_isValidUuid(resolvedCityId)) {
        try {
          final firstCity = await client.from('cities').select('id').limit(1).maybeSingle();
          if (firstCity != null && firstCity['id'] != null) {
            resolvedCityId = firstCity['id'].toString();
          }
        } catch (e) {
          debugPrint('⚠️ [TOURNAMENTS_REMOTE] Failed to fetch fallback city: $e');
        }
      }
    }

    try {
      final Map<String, dynamic> rpcParams = {
        'p_title_ar': (tournament.titleAr != null && tournament.titleAr!.isNotEmpty) ? tournament.titleAr : tournament.title,
        'p_title_en': (tournament.titleEn != null && tournament.titleEn!.isNotEmpty) ? tournament.titleEn : tournament.title,
        'p_description_ar': tournament.descriptionAr ?? tournament.rules,
        'p_description_en': tournament.descriptionEn ?? tournament.rules,
        'p_game_name': tournament.gameTitle,
        'p_bracket_size': tournament.treeSize,
        'p_max_participants': tournament.maxPlayers,
        'p_entry_fee': tournament.entryFee,
        'p_registration_opens_at': tournament.registrationOpensAt?.toUtc().toIso8601String() ?? tournament.startDate.toUtc().toIso8601String(),
        'p_registration_closes_at': (tournament.registrationClosesAt ?? tournament.registrationDeadline).toUtc().toIso8601String(),
        'p_payment_deadline_minutes': tournament.paymentDeadlineMinutes,
        'p_check_in_opens_at': tournament.checkInOpensAt?.toUtc().toIso8601String() ?? tournament.startDate.toUtc().toIso8601String(),
        'p_check_in_closes_at': tournament.checkInClosesAt?.toUtc().toIso8601String() ?? tournament.startDate.toUtc().toIso8601String(),
        'p_tournament_starts_at': (tournament.tournamentStartsAt ?? tournament.startDate).toUtc().toIso8601String(),
        'p_visibility_scope': tournament.visibilityScope,
        'p_visibility_radius_km': tournament.visibilityScope == 'radius' ? tournament.visibilityRadiusKm : null,
      };

      if (_isValidUuid(tournament.loungeId)) {
        rpcParams['p_lounge_id'] = tournament.loungeId;
      }
      if (_isValidUuid(resolvedCityId)) {
        rpcParams['p_city_id'] = resolvedCityId;
      }

      dynamic response;
      try {
        debugPrint('🔵 [TOURNAMENTS_REMOTE] Calling create_tournament_with_visibility RPC with params: $rpcParams');
        response = await client.rpc('create_tournament_with_visibility', params: rpcParams);
      } catch (e) {
        debugPrint('⚠️ [TOURNAMENTS_REMOTE] create_tournament_with_visibility RPC error ($e), trying create_tournament');
        response = await client.rpc('create_tournament', params: rpcParams);
      }

      if (response != null) {
        if (response is Map) {
          final model = TournamentModel.fromJson(Map<String, dynamic>.from(response));
          createdId = model.id;
        } else if (response is String) {
          createdId = response;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] create_tournament RPC error: $e, falling back to direct insert');
    }

    if (createdId == null || createdId.isEmpty) {
      final insertMap = tournament.toJson();
      if (_isValidUuid(resolvedCityId)) {
        insertMap['city_id'] = resolvedCityId;
      }
      insertMap['visibility_scope'] = tournament.visibilityScope;
      insertMap['visibility_radius_km'] = tournament.visibilityScope == 'radius' ? tournament.visibilityRadiusKm : null;

      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId != null && _isValidUuid(currentUserId)) {
        insertMap['created_by'] = currentUserId;
      }
      debugPrint('🔵 [TOURNAMENTS_REMOTE] Executing direct insert: $insertMap');
      final inserted = await client.from('tournaments').insert(insertMap).select().single();
      final model = TournamentModel.fromJson(Map<String, dynamic>.from(inserted));
      createdId = model.id;
    }

    if (tournament.bannerUrl != null && tournament.bannerUrl!.isNotEmpty && createdId != null && createdId.isNotEmpty) {
      await client.from('tournaments').update({
        'banner_url': tournament.bannerUrl,
      }).eq('id', createdId);
    }

    final finalRes = await client.from('tournaments').select('''
      *,
      lounges(name),
      tournament_participants(id)
    ''').eq('id', createdId!).single();

    return TournamentModel.fromJson(Map<String, dynamic>.from(finalRes));
  }

  @override
  Future<TournamentModel> updateTournament(TournamentModel tournament) async {
    try {
      final rpcParams = <String, dynamic>{
        'p_tournament_id': tournament.id,
        'p_title_ar': (tournament.titleAr != null && tournament.titleAr!.isNotEmpty) ? tournament.titleAr : tournament.title,
        'p_title_en': (tournament.titleEn != null && tournament.titleEn!.isNotEmpty) ? tournament.titleEn : tournament.title,
        'p_description_ar': tournament.descriptionAr ?? tournament.rules,
        'p_description_en': tournament.descriptionEn ?? tournament.rules,
        'p_game_name': tournament.gameTitle,
        'p_max_participants': tournament.maxPlayers,
        'p_entry_fee': tournament.entryFee,
        'p_registration_opens_at': tournament.registrationOpensAt?.toUtc().toIso8601String() ?? tournament.startDate.toUtc().toIso8601String(),
        'p_registration_closes_at': (tournament.registrationClosesAt ?? tournament.registrationDeadline).toUtc().toIso8601String(),
        'p_payment_deadline_minutes': tournament.paymentDeadlineMinutes,
        'p_check_in_opens_at': tournament.checkInOpensAt?.toUtc().toIso8601String() ?? tournament.startDate.toUtc().toIso8601String(),
        'p_check_in_closes_at': tournament.checkInClosesAt?.toUtc().toIso8601String() ?? tournament.startDate.toUtc().toIso8601String(),
        'p_tournament_starts_at': (tournament.tournamentStartsAt ?? tournament.startDate).toUtc().toIso8601String(),
        'p_visibility_scope': tournament.visibilityScope,
        'p_visibility_radius_km': tournament.visibilityScope == 'radius' ? tournament.visibilityRadiusKm : null,
      };

      if (_isValidUuid(tournament.cityId)) {
        rpcParams['p_city_id'] = tournament.cityId;
      }

      try {
        debugPrint('🔵 [TOURNAMENTS_REMOTE] Calling update_tournament_with_visibility RPC');
        await client.rpc('update_tournament_with_visibility', params: rpcParams);
      } catch (e) {
        debugPrint('⚠️ [TOURNAMENTS_REMOTE] update_tournament_with_visibility RPC error ($e), trying update_tournament');
        await client.rpc('update_tournament', params: rpcParams);
      }
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] update_tournament RPC error: $e, falling back to direct update');
      final updateMap = tournament.toJson();
      updateMap['visibility_scope'] = tournament.visibilityScope;
      updateMap['visibility_radius_km'] = tournament.visibilityScope == 'radius' ? tournament.visibilityRadiusKm : null;
      if (tournament.cityId != null && _isValidUuid(tournament.cityId)) {
        updateMap['city_id'] = tournament.cityId;
      }
      await client
          .from('tournaments')
          .update(updateMap)
          .eq('id', tournament.id);
    }

    if (tournament.bannerUrl != null && tournament.bannerUrl!.isNotEmpty) {
      await client.from('tournaments').update({
        'banner_url': tournament.bannerUrl,
      }).eq('id', tournament.id);
    }

    final updatedRes = await client.from('tournaments').select('''
      *,
      lounges(name),
      tournament_participants(id)
    ''').eq('id', tournament.id).single();

    return TournamentModel.fromJson(Map<String, dynamic>.from(updatedRes));
  }

  @override
  Future<void> publishTournament(String tournamentId) async {
    try {
      await client.rpc('publish_tournament', params: {
        'p_tournament_id': tournamentId,
        'p_open': true,
      });
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] publish_tournament RPC error: $e, fallback update');
      await client
          .from('tournaments')
          .update({'status': 'registration_open'})
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
          .select()
          .eq('tournament_id', tournamentId)
          .order('created_at', ascending: false);

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
      try {
        final plainResponse = await client
            .from('tournament_participants')
            .select()
            .eq('tournament_id', tournamentId)
            .order('created_at', ascending: false);

        return (plainResponse as List).map((json) {
          return TournamentParticipantModel.fromJson(Map<String, dynamic>.from(json));
        }).toList();
      } catch (_) {
        return [];
      }
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
  Future<void> promoteWaitlist(String tournamentId) async {
    try {
      await client.rpc('promote_tournament_waitlist', params: {'p_tournament_id': tournamentId});
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] promote_tournament_waitlist RPC error: $e');
      rethrow;
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
            player1:tournament_participants!tournament_matches_player1_id_fkey(*),
            player2:tournament_participants!tournament_matches_player2_id_fkey(*),
            rooms(name)
          ''')
          .eq('tournament_id', tournamentId)
          .order('round_number', ascending: true);

      return (response as List).map((json) {
        return TournamentMatchModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] getMatches join query error: $e');
      try {
        final plainResponse = await client
            .from('tournament_matches')
            .select()
            .eq('tournament_id', tournamentId)
            .order('round_number', ascending: true);

        return (plainResponse as List).map((json) {
          return TournamentMatchModel.fromJson(Map<String, dynamic>.from(json));
        }).toList();
      } catch (_) {
        return [];
      }
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
