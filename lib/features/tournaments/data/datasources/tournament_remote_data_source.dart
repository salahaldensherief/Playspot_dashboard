import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/tournament_audit_log_model.dart';
import '../models/tournament_match_model.dart';
import '../models/tournament_model.dart';
import '../models/tournament_participant_model.dart';
import '../models/tournament_prize_model.dart';
import '../models/tournament_prize_reward_model.dart';

abstract class TournamentRemoteDataSource {
  Future<List<TournamentModel>> getTournaments({double? latitude, double? longitude, String? loungeId, String? status});
  Future<TournamentModel> createTournament(TournamentModel tournament);
  Future<TournamentModel> updateTournament(TournamentModel tournament);
  Future<void> saveTournamentPrizes(String tournamentId, List<TournamentPrizeModel> prizes);
  Future<void> publishTournament(String tournamentId);
  Future<void> cancelTournament(String tournamentId, String reason);
  Future<void> deleteDraftTournament(String tournamentId);
  Future<void> deleteTournament(String tournamentId);

  Future<List<TournamentParticipantModel>> getParticipants(String tournamentId);
  Future<void> approvePayment(String participantId);
  Future<void> rejectPayment(String participantId, String reason);
  Future<void> recordCashPayment(String participantId);
  Future<void> promoteWaitlist(String tournamentId);
  Future<void> checkInParticipant(String participantId);
  Future<void> withdrawParticipant(String participantId);

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
  Future<List<TournamentModel>> getTournaments({double? latitude, double? longitude, String? loungeId, String? status}) async {
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
    String? cityId = tournament.cityId;
    if ((cityId == null || cityId.isEmpty) && tournament.loungeId != null) {
      try {
        final loungeData = await client.from('lounges').select('city_id').eq('id', tournament.loungeId!).maybeSingle();
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
        'p_registration_opens_at': tournament.registrationOpensAt?.toUtc().toIso8601String() ?? tournament.startDate.toUtc().toIso8601String(),
        'p_registration_closes_at': (tournament.registrationClosesAt ?? tournament.registrationDeadline).toUtc().toIso8601String(),
        'p_payment_deadline_minutes': tournament.paymentDeadlineMinutes,
        'p_check_in_opens_at': tournament.checkInOpensAt?.toUtc().toIso8601String() ?? tournament.startDate.toUtc().toIso8601String(),
        'p_check_in_closes_at': tournament.checkInClosesAt?.toUtc().toIso8601String() ?? tournament.endDate.toUtc().toIso8601String(),
        'p_tournament_starts_at': (tournament.tournamentStartsAt ?? tournament.startDate).toUtc().toIso8601String(),
      });

      String? createdId;
      if (response != null) {
        if (response is Map) {
          final model = TournamentModel.fromJson(Map<String, dynamic>.from(response));
          createdId = model.id;
        } else if (response is String) {
          createdId = response;
        }
      }

      if (createdId == null || createdId.isEmpty) {
        throw Exception('Failed to create tournament via RPC');
      }

      if (tournament.bannerUrl != null && tournament.bannerUrl!.isNotEmpty) {
        await client.from('tournaments').update({
          'banner_url': tournament.bannerUrl,
        }).eq('id', createdId);
      }

      if (tournament.prizes.isNotEmpty) {
        await saveTournamentPrizes(
          createdId,
          tournament.prizes.map((p) => TournamentPrizeModel.fromEntity(p)).toList(),
        );
      }

      final finalRes = await client.from('tournaments').select('''
        *,
        lounges(name),
        tournament_participants(id),
        tournament_prizes (
          id,
          tournament_id,
          placement,
          tournament_prize_rewards (*)
        )
      ''').eq('id', createdId).single();

      return TournamentModel.fromJson(Map<String, dynamic>.from(finalRes));
    } on PostgrestException catch (error) {
      AppLogger.error('create_tournament RPC error: ${error.message}', error);
      throw Exception(error.message);
    } catch (e) {
      AppLogger.error('createTournament error: $e', e);
      rethrow;
    }
  }

  @override
  Future<TournamentModel> updateTournament(TournamentModel tournament) async {
    try {
      await client.rpc('update_tournament', params: {
        'p_tournament_id': tournament.id,
        'p_title_ar': tournament.titleAr ?? tournament.title,
        'p_title_en': tournament.titleEn ?? tournament.title,
        'p_description_ar': tournament.descriptionAr ?? tournament.rules,
        'p_description_en': tournament.descriptionEn ?? tournament.rules,
        'p_game_name': tournament.gameTitle,
        'p_max_participants': tournament.maxPlayers,
        'p_entry_fee': tournament.entryFee,
        'p_registration_opens_at': tournament.registrationOpensAt?.toUtc().toIso8601String() ?? tournament.startDate.toUtc().toIso8601String(),
        'p_registration_closes_at': (tournament.registrationClosesAt ?? tournament.registrationDeadline).toUtc().toIso8601String(),
        'p_payment_deadline_minutes': tournament.paymentDeadlineMinutes,
        'p_check_in_opens_at': tournament.checkInOpensAt?.toUtc().toIso8601String() ?? tournament.startDate.toUtc().toIso8601String(),
        'p_check_in_closes_at': tournament.checkInClosesAt?.toUtc().toIso8601String() ?? tournament.endDate.toUtc().toIso8601String(),
        'p_tournament_starts_at': (tournament.tournamentStartsAt ?? tournament.startDate).toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] update_tournament RPC error: $e, falling back to direct update');
      final updateMap = tournament.toJson();
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

    if (tournament.prizes.isNotEmpty) {
      await saveTournamentPrizes(
        tournament.id,
        tournament.prizes.map((p) => TournamentPrizeModel.fromEntity(p)).toList(),
      );
    }

    final updatedRes = await client.from('tournaments').select('''
      *,
      lounges(name),
      tournament_participants(id),
      tournament_prizes (
        id,
        tournament_id,
        placement,
        tournament_prize_rewards (*)
      )
    ''').eq('id', tournament.id).single();

    return TournamentModel.fromJson(Map<String, dynamic>.from(updatedRes));
  }

  @override
  Future<void> saveTournamentPrizes(String tournamentId, List<TournamentPrizeModel> prizes) async {
    try {
      try {
        final existingPrizes = await client
            .from('tournament_prizes')
            .select('id')
            .eq('tournament_id', tournamentId);
        final existingIds = (existingPrizes as List)
            .map((p) => p['id'] as String)
            .where((id) => id.isNotEmpty)
            .toList();
        if (existingIds.isNotEmpty) {
          await client
              .from('tournament_prize_rewards')
              .delete()
              .inFilter('prize_id', existingIds);
        }
        await client
            .from('tournament_prizes')
            .delete()
            .eq('tournament_id', tournamentId);
      } catch (delErr) {
        debugPrint('⚠️ [TOURNAMENTS_REMOTE] delete existing prizes error: $delErr');
      }

      for (final prize in prizes) {
        final prizeInsertRes = await client.from('tournament_prizes').insert({
          'tournament_id': tournamentId,
          'placement': prize.placement,
        }).select().single();

        final prizeId = prizeInsertRes['id'] as String;

        if (prize.rewards.isNotEmpty) {
          final rewardsData = prize.rewards.map((r) {
            final rewardModel = TournamentPrizeRewardModel.fromEntity(r);
            return {
              'prize_id': prizeId,
              'type': rewardModel.type.toDbString(),
              if (rewardModel.title != null && rewardModel.title!.isNotEmpty) 'title': rewardModel.title,
              if (rewardModel.titleAr != null && rewardModel.titleAr!.isNotEmpty) 'title_ar': rewardModel.titleAr,
              if (rewardModel.titleEn != null && rewardModel.titleEn!.isNotEmpty) 'title_en': rewardModel.titleEn,
              if (rewardModel.description != null && rewardModel.description!.isNotEmpty) 'description': rewardModel.description,
              if (rewardModel.descriptionAr != null && rewardModel.descriptionAr!.isNotEmpty) 'description_ar': rewardModel.descriptionAr,
              if (rewardModel.descriptionEn != null && rewardModel.descriptionEn!.isNotEmpty) 'description_en': rewardModel.descriptionEn,
              if (rewardModel.value != null) 'value': rewardModel.value,
              if (rewardModel.currency != null && rewardModel.currency!.isNotEmpty) 'currency': rewardModel.currency,
              if (rewardModel.metadata != null) 'metadata': rewardModel.metadata,
              if (rewardModel.deliveryStatus != null) 'delivery_status': rewardModel.deliveryStatus,
            };
          }).toList();

          await client.from('tournament_prize_rewards').insert(rewardsData);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] saveTournamentPrizes error: $e');
      rethrow;
    }
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
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw Exception('سبب إلغاء البطولة إجباري ولا يمكن أن يكون فارغاً.');
    }

    try {
      await client.rpc('cancel_tournament', params: {
        'p_tournament_id': tournamentId,
        'p_reason': cleanReason,
      });
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] cancel_tournament RPC error: $e, fallback update');
      await client
          .from('tournaments')
          .update({
            'status': 'cancelled',
            'cancellation_reason': cleanReason,
          })
          .eq('id', tournamentId);
    }
  }

  @override
  Future<void> deleteDraftTournament(String tournamentId) async {
    // Rule: Do NOT delete draft if it has tournament_participants or tournament_matches
    try {
      final participantsRes = await client
          .from('tournament_participants')
          .select('id')
          .eq('tournament_id', tournamentId)
          .limit(1);

      final matchesRes = await client
          .from('tournament_matches')
          .select('id')
          .eq('tournament_id', tournamentId)
          .limit(1);

      final hasParticipants = (participantsRes as List).isNotEmpty;
      final hasMatches = (matchesRes as List).isNotEmpty;

      if (hasParticipants || hasMatches) {
        throw Exception('لا يمكن حذف المسودة لوجود مشاركين أو مباريات مسجلة فيها. يجب استخدام الإلغاء بدلاً من الحذف.');
      }
    } catch (e) {
      if (e.toString().contains('لا يمكن حذف المسودة')) rethrow;
    }

    try {
      await client.rpc('delete_draft_tournament', params: {'p_tournament_id': tournamentId});
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] delete_draft_tournament RPC error: $e, fallback delete for draft status');
      await client.from('tournaments').delete().eq('id', tournamentId).eq('status', 'draft');
    }
  }

  @override
  Future<void> deleteTournament(String tournamentId, {String? cancelReason}) async {
    // Rule: Check status first.
    // If draft without participants/matches -> delete_draft_tournament.
    // If published/started or has participants/matches -> cancel_tournament with non-empty reason.
    try {
      final tData = await client
          .from('tournaments')
          .select('status')
          .eq('id', tournamentId)
          .maybeSingle();

      if (tData == null) {
        throw Exception('البطولة غير موجودة');
      }

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

      // Non-draft tournament (published, in-progress, completed, etc.): MUST cancel, NEVER delete.
      final reason = (cancelReason != null && cancelReason.trim().isNotEmpty)
          ? cancelReason.trim()
          : 'إلغاء البطولة بقرار من الإدارة';

      await cancelTournament(tournamentId, reason);
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] deleteTournament error: $e');
      rethrow;
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

      final rawList = (response as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (rawList.isEmpty) return [];

      final userIds = rawList
          .map((json) => json['user_id']?.toString())
          .where((id) => id != null && id.trim().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> profilesMap = {};
      if (userIds.isNotEmpty) {
        try {
          final profilesResponse = await client
              .from('profiles')
              .select('id, full_name, phone, email, avatar_url')
              .inFilter('id', userIds);

          for (final p in profilesResponse as List) {
            final pMap = Map<String, dynamic>.from(p as Map);
            final pId = pMap['id']?.toString();
            if (pId != null) {
              profilesMap[pId] = pMap;
            }
          }
        } catch (e) {
          AppLogger.error('Profiles batch fetch failed for participants', e);
        }
      }

      final list = rawList.map((json) {
        final uId = json['user_id']?.toString();
        if (uId != null && profilesMap.containsKey(uId)) {
          json['profiles'] = profilesMap[uId];
        }
        return TournamentParticipantModel.fromJson(json);
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
            AppLogger.error('Failed to generate signed URL for receipt', storageErr);
          }
        }
        return p;
      }));

      return resultWithSignedUrls;
    } catch (e) {
      AppLogger.error('getParticipants error: $e', e);
      return [];
    }
  }

  @override
  Future<void> approvePayment(String participantId) async {
    try {
      await client.rpc('approve_tournament_payment', params: {'p_participant_id': participantId});
    } catch (e) {
      try {
        await client.rpc('approve_tournament_payment', params: {'participant_id': participantId});
      } catch (e2) {
        debugPrint('⚠️ [TOURNAMENTS_REMOTE] approve_tournament_payment error: $e2');
        rethrow;
      }
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
      try {
        await client.rpc('reject_tournament_payment', params: {
          'participant_id': participantId,
          'reason': reason,
        });
      } catch (e2) {
        debugPrint('⚠️ [TOURNAMENTS_REMOTE] reject_tournament_payment error: $e2');
        rethrow;
      }
    }
  }

  @override
  Future<void> recordCashPayment(String participantId) async {
    try {
      final participantRes = await client
          .from('tournament_participants')
          .select('tournament_id, registration_status, payment_status, tournaments(entry_fee)')
          .eq('id', participantId)
          .maybeSingle();

      double amount = 0.0;
      String registrationStatus = 'unknown';
      String paymentStatus = 'unknown';

      if (participantRes != null) {
        registrationStatus = participantRes['registration_status']?.toString() ?? participantRes['status']?.toString() ?? 'unknown';
        paymentStatus = participantRes['payment_status']?.toString() ?? 'unknown';
        final tData = participantRes['tournaments'];
        if (tData is Map) {
          amount = (tData['entry_fee'] as num?)?.toDouble() ?? 0.0;
        }
      }

      debugPrint(
        '[CASH_PAYMENT] '
        'participantId=$participantId '
        'amount=$amount '
        'registrationStatus=$registrationStatus '
        'paymentStatus=$paymentStatus',
      );

      await client.rpc('record_cash_tournament_payment', params: {
        'p_participant_id': participantId,
        'p_amount': amount,
        'p_reference_note': 'Cash payment recorded by admin',
      });
    } on PostgrestException catch (e) {
      if (e.code == 'P0001' && (e.message == 'payment_not_allowed' || e.message.contains('payment_not_allowed'))) {
        throw Exception('Payment is not allowed: Participant registration has expired or payment deadline has passed.');
      }
      rethrow;
    } catch (e) {
      AppLogger.error('recordCashPayment failed', e);
      rethrow;
    }
  }

  @override
  Future<void> checkInParticipant(String participantId) async {
    try {
      await client.rpc('check_in_tournament_participant', params: {'p_participant_id': participantId});
    } catch (e) {
      try {
        await client.rpc('check_in_tournament_participant', params: {'participant_id': participantId});
      } catch (e2) {
        debugPrint('⚠️ [TOURNAMENTS_REMOTE] check_in_tournament_participant error: $e2');
        rethrow;
      }
    }
  }

  @override
  Future<void> withdrawParticipant(String participantId) async {
    try {
      await client.rpc('withdraw_from_tournament', params: {'p_participant_id': participantId});
    } catch (e) {
      try {
        await client.rpc('withdraw_from_tournament', params: {'participant_id': participantId});
      } catch (e2) {
        debugPrint('⚠️ [TOURNAMENTS_REMOTE] withdraw_from_tournament error: $e2, falling back to update status');
        await client
            .from('tournament_participants')
            .update({'registration_status': 'withdrawn'})
            .eq('id', participantId);
      }
    }
  }

  @override
  Future<void> promoteWaitlist(String tournamentId) async {
    try {
      await client.rpc('promote_waitlist', params: {'p_tournament_id': tournamentId});
    } catch (e) {
      debugPrint('⚠️ [TOURNAMENTS_REMOTE] promote_waitlist RPC error: $e');
      rethrow;
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
      try {
        await client.rpc('start_tournament_match', params: {
          'match_id': matchId,
          'room_id': roomId,
        });
      } catch (e2) {
        debugPrint('⚠️ [TOURNAMENTS_REMOTE] start_tournament_match error: $e2');
        rethrow;
      }
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
