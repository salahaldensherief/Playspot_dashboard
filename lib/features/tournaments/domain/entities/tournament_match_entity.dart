import 'package:equatable/equatable.dart';

enum MatchStatus {
  scheduled,
  inProgress,
  completed,
  disputed;

  static MatchStatus fromString(String? value) {
    switch (value) {
      case 'in_progress':
        return MatchStatus.inProgress;
      case 'completed':
        return MatchStatus.completed;
      case 'disputed':
        return MatchStatus.disputed;
      case 'scheduled':
      default:
        return MatchStatus.scheduled;
    }
  }

  String toDbString() {
    switch (this) {
      case MatchStatus.inProgress:
        return 'in_progress';
      case MatchStatus.completed:
        return 'completed';
      case MatchStatus.disputed:
        return 'disputed';
      case MatchStatus.scheduled:
        return 'scheduled';
    }
  }
}

class TournamentMatchEntity extends Equatable {
  final String id;
  final String tournamentId;
  final int round;
  final int matchNumber;
  final String? player1Id;
  final String? player1Name;
  final String? player2Id;
  final String? player2Name;
  final String? winnerId;
  final int player1Score;
  final int player2Score;
  final MatchStatus status;
  final String? roomId;
  final String? roomName;
  final String? proofUrl;
  final String? disputeReason;
  final String? resolutionNotes;
  final bool isBye;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const TournamentMatchEntity({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.matchNumber,
    this.player1Id,
    this.player1Name,
    this.player2Id,
    this.player2Name,
    this.winnerId,
    this.player1Score = 0,
    this.player2Score = 0,
    required this.status,
    this.roomId,
    this.roomName,
    this.proofUrl,
    this.disputeReason,
    this.resolutionNotes,
    this.isBye = false,
    this.startedAt,
    this.completedAt,
  });

  bool get isDisputed => status == MatchStatus.disputed;
  bool get isCompleted => status == MatchStatus.completed;
  bool get isInProgress => status == MatchStatus.inProgress;
  bool get isScheduled => status == MatchStatus.scheduled;

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        round,
        matchNumber,
        player1Id,
        player1Name,
        player2Id,
        player2Name,
        winnerId,
        player1Score,
        player2Score,
        status,
        roomId,
        roomName,
        proofUrl,
        disputeReason,
        resolutionNotes,
        isBye,
        startedAt,
        completedAt,
      ];
}
