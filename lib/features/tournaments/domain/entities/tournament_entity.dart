import 'package:equatable/equatable.dart';

enum TournamentStatus {
  draft,
  published,
  inProgress,
  completed,
  cancelled;

  static TournamentStatus fromString(String? value) {
    switch (value) {
      case 'published':
        return TournamentStatus.published;
      case 'in_progress':
        return TournamentStatus.inProgress;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      case 'draft':
      default:
        return TournamentStatus.draft;
    }
  }

  String toDbString() {
    switch (this) {
      case TournamentStatus.published:
        return 'published';
      case TournamentStatus.inProgress:
        return 'in_progress';
      case TournamentStatus.completed:
        return 'completed';
      case TournamentStatus.cancelled:
        return 'cancelled';
      case TournamentStatus.draft:
        return 'draft';
    }
  }
}

class TournamentEntity extends Equatable {
  final String id;
  final String? loungeId;
  final String? loungeName;
  final String title;
  final String? gameTitle;
  final String? bannerUrl;
  final int treeSize; // 8, 16, 32
  final TournamentStatus status;
  final double entryFee;
  final double prizePool;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final int minPlayers;
  final int maxPlayers;
  final String? rules;
  final int registeredCount;
  final DateTime? createdAt;

  const TournamentEntity({
    required this.id,
    this.loungeId,
    this.loungeName,
    required this.title,
    this.gameTitle,
    this.bannerUrl,
    required this.treeSize,
    required this.status,
    required this.entryFee,
    required this.prizePool,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    required this.minPlayers,
    required this.maxPlayers,
    this.rules,
    this.registeredCount = 0,
    this.createdAt,
  });

  bool get isDraft => status == TournamentStatus.draft;
  bool get isPublished => status == TournamentStatus.published;
  bool get isInProgress => status == TournamentStatus.inProgress;
  bool get isCompleted => status == TournamentStatus.completed;
  bool get isCancelled => status == TournamentStatus.cancelled;

  bool get canDeleteDraft => isDraft && registeredCount == 0;
  bool get canDrawBracket => (isPublished || isDraft) && registeredCount >= minPlayers;

  @override
  List<Object?> get props => [
        id,
        loungeId,
        loungeName,
        title,
        gameTitle,
        bannerUrl,
        treeSize,
        status,
        entryFee,
        prizePool,
        startDate,
        endDate,
        registrationDeadline,
        minPlayers,
        maxPlayers,
        rules,
        registeredCount,
        createdAt,
      ];
}
