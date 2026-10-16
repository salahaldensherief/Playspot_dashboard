import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tournament_match_model.dart';
import 'tournament_roster_remote_helper.dart';

class TournamentMatchRemoteHelper {
  final SupabaseClient client;
  final Set<RealtimeChannel> _disputesChannels = {};
  int _watchSerial = 0;

  TournamentMatchRemoteHelper(this.client);

  Future<List<TournamentMatchModel>> drawBracket(String tournamentId) async {
    final response = await client.rpc(
      'draw_tournament_bracket',
      params: {'p_tournament_id': tournamentId},
    );
    if (response is List) {
      return response.map((json) {
        return TournamentMatchModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    }
    // The deployed RPC returns the number of generated matches. Only fetch
    // after an acknowledged draw; a rejected RPC must reach the caller.
    if (response is! int || response < 0) {
      throw const FormatException('Invalid tournament draw response');
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
          .order('round_number', ascending: true)
          .order('match_order', ascending: true);

      return _matchesWithNames(response as List, tournamentId);
    } on PostgrestException catch (e) {
      // Older schemas may lack the embedded relationship. Permission and
      // transport failures are not evidence that the tournament is empty.
      if (e.code != 'PGRST200' && e.code != 'PGRST201') {
        rethrow;
      }
      final plainResponse = await client
          .from('tournament_matches')
          .select()
          .eq('tournament_id', tournamentId)
          .order('round_number', ascending: true)
          .order('match_order', ascending: true);

      return _matchesWithNames(plainResponse as List, tournamentId);
    }
  }

  Future<List<TournamentMatchModel>> _matchesWithNames(
    List rows,
    String tournamentId,
  ) async {
    final needsNames = rows.any(
      (row) => row['player1_id'] != null || row['player2_id'] != null,
    );
    final names = needsNames
        ? await fetchTournamentParticipantNames(client, tournamentId)
        : <String, String>{};
    return rows.map((row) {
      final json = Map<String, dynamic>.from(row);
      if (names[json['player1_id']] case final name?) {
        json['player1_name'] = name;
      }
      if (names[json['player2_id']] case final name?) {
        json['player2_name'] = name;
      }
      return TournamentMatchModel.fromJson(json);
    }).toList();
  }

  Future<void> startMatch(String matchId, {String? roomId}) async {
    await client.rpc(
      'start_tournament_match',
      params: {
        'p_match_id': matchId,
        if (roomId != null && roomId.trim().isNotEmpty)
          'p_room_id': roomId.trim(),
      },
    );
  }

  Future<void> resolveDispute(
    String matchId, {
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  }) async {
    await client.rpc(
      'resolve_tournament_dispute',
      params: {
        'p_match_id': matchId,
        'p_winner_id': winnerId,
        'p_score_player1': p1Score,
        'p_score_player2': p2Score,
        'p_notes': resolutionNotes,
      },
    );
  }

  Stream<List<TournamentMatchModel>> watchDisputedMatches(String tournamentId) {
    final controller = StreamController<List<TournamentMatchModel>>();
    var revision = 0;
    Future<void> refresh() async {
      final requestRevision = ++revision;
      try {
        final matches = await getMatches(tournamentId);
        if (!controller.isClosed && requestRevision == revision) {
          controller.add(matches.where((m) => m.isDisputed).toList());
        }
      } catch (error, stack) {
        if (!controller.isClosed && requestRevision == revision) {
          controller.addError(error, stack);
        }
      }
    }

    unawaited(refresh());
    final channel = client
        .channel(
          'public:tournament_matches:disputed:$tournamentId:${_watchSerial++}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tournament_matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournament_id',
            value: tournamentId,
          ),
          callback: (_) {
            // With the default replica identity, oldRecord contains only the
            // key. A resolved or deleted dispute still needs a fresh read.
            unawaited(refresh());
          },
        )
        .subscribe();
    _disputesChannels.add(channel);

    controller.onCancel = () {
      revision++;
      if (_disputesChannels.remove(channel)) {
        unawaited(client.removeChannel(channel));
      }
    };

    return controller.stream;
  }

  void dispose() {
    for (final channel in _disputesChannels) {
      unawaited(client.removeChannel(channel));
    }
    _disputesChannels.clear();
  }
}
