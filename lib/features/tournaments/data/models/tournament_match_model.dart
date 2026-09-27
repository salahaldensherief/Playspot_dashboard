import '../../domain/entities/tournament_match_entity.dart';

class TournamentMatchModel extends TournamentMatchEntity {
  const TournamentMatchModel({
    required super.id,
    required super.tournamentId,
    required super.round,
    required super.matchNumber,
    super.player1Id,
    super.player1Name,
    super.player2Id,
    super.player2Name,
    super.winnerId,
    super.player1Score = 0,
    super.player2Score = 0,
    required super.status,
    super.roomId,
    super.roomName,
    super.proofUrl,
    super.disputeReason,
    super.resolutionNotes,
    super.isBye = false,
    super.startedAt,
    super.completedAt,
  });

  factory TournamentMatchModel.fromJson(Map<String, dynamic> json) {
    String? p1Name;
    String? p2Name;
    String? roomNameVal;

    if (json['player1'] != null && json['player1'] is Map) {
      p1Name = json['player1']['user_name'] as String? ?? json['player1']['full_name'] as String?;
    } else if (json['p1_profile'] != null && json['p1_profile'] is Map) {
      p1Name = json['p1_profile']['full_name'] as String?;
    }
    if (json['player2'] != null && json['player2'] is Map) {
      p2Name = json['player2']['user_name'] as String? ?? json['player2']['full_name'] as String?;
    } else if (json['p2_profile'] != null && json['p2_profile'] is Map) {
      p2Name = json['p2_profile']['full_name'] as String?;
    }
    if (json['rooms'] != null && json['rooms'] is Map) {
      roomNameVal = json['rooms']['name'] as String?;
    }

    final roundVal = json['round_number'] as int? ?? json['round'] as int? ?? 1;

    return TournamentMatchModel(
      id: json['id'] as String? ?? '',
      tournamentId: json['tournament_id'] as String? ?? '',
      round: roundVal,
      matchNumber: json['match_number'] as int? ?? 1,
      player1Id: json['player1_id'] as String?,
      player1Name: p1Name ?? json['player1_name'] as String?,
      player2Id: json['player2_id'] as String?,
      player2Name: p2Name ?? json['player2_name'] as String?,
      winnerId: json['winner_id'] as String?,
      player1Score: json['player1_score'] as int? ?? 0,
      player2Score: json['player2_score'] as int? ?? 0,
      status: MatchStatus.fromString(json['status'] as String?),
      roomId: json['room_id'] as String?,
      roomName: roomNameVal ?? json['room_name'] as String?,
      proofUrl: json['proof_url'] as String?,
      disputeReason: json['dispute_reason'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      isBye: json['is_bye'] as bool? ?? false,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }
}
