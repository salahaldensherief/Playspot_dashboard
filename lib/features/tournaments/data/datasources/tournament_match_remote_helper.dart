import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../models/tournament_match_model.dart';

class TournamentMatchRemoteHelper {
  final SupabaseClient client;
  RealtimeChannel? _disputesChannel;

  TournamentMatchRemoteHelper(this.client);

  Future<List<TournamentMatchModel>> drawBracket(String tournamentId) async {
    try {
      final response = await client.rpc(
        'draw_tournament_bracket',
        params: {'p_tournament_id': tournamentId},
      );

      if (response != null && response is List) {
        return response.map((json) {
          return TournamentMatchModel.fromJson(Map<String, dynamic>.from(json));
        }).toList();
      }
    } catch (e) {
      AppLogger.warning('draw_tournament_bracket RPC error', e);
    }

    return getMatches(tournamentId);
  }

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

  Future<void> startMatch(String matchId, {String? roomId}) async {
    try {
      await client.rpc(
        'start_tournament_match',
        params: {'p_match_id': matchId, 'p_room_id': roomId},
      );
    } catch (e) {
      try {
        await client.rpc(
          'start_tournament_match',
          params: {'match_id': matchId, 'room_id': roomId},
        );
      } catch (e2) {
        AppLogger.warning('start_tournament_match error', e2);
        rethrow;
      }
    }
  }

  Future<void> resolveDispute(
    String matchId, {
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  }) async {
    try {
      await client.rpc(
        'resolve_tournament_dispute',
        params: {
          'p_match_id': matchId,
          'p_winner_id': winnerId,
          'p_p1_score': p1Score,
          'p_p2_score': p2Score,
          'p_resolution_notes': resolutionNotes,
        },
      );
    } catch (e) {
      AppLogger.warning(
        'resolve_tournament_dispute RPC error, fallback update',
        e,
      );
      await client
          .from('tournament_matches')
          .update({
            'status': 'completed',
            'winner_id': winnerId,
            'player1_score': p1Score,
            'player2_score': p2Score,
            'resolution_notes': resolutionNotes,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId);
    }
  }

  Stream<List<TournamentMatchModel>> watchDisputedMatches(String tournamentId) {
    if (_disputesChannel != null) {
      client.removeChannel(_disputesChannel!);
    }

    final controller = StreamController<List<TournamentMatchModel>>();

    getMatches(tournamentId)
        .then((allMatches) {
          if (!controller.isClosed) {
            controller.add(allMatches.where((m) => m.isDisputed).toList());
          }
        })
        .catchError((err) {
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

              if (newStatus == 'disputed' || oldStatus == 'disputed') {
                final freshMatches = await getMatches(tournamentId);
                if (!controller.isClosed) {
                  controller.add(
                    freshMatches.where((m) => m.isDisputed).toList(),
                  );
                }
              }
            } catch (e) {
              AppLogger.warning('Realtime update fetch error', e);
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

  void dispose() {
    if (_disputesChannel != null) {
      client.removeChannel(_disputesChannel!);
      _disputesChannel = null;
    }
  }
}
