import 'package:equatable/equatable.dart';
import '../domain/entities/tournament_audit_log_entity.dart';
import '../domain/entities/tournament_entity.dart';
import '../domain/entities/tournament_match_entity.dart';
import '../domain/entities/tournament_participant_entity.dart';

enum TournamentCubitStatus { initial, loading, success, actionSuccess, failure }

class TournamentState extends Equatable {
  final TournamentCubitStatus status;
  final List<TournamentEntity> tournaments;
  final TournamentEntity? selectedTournament;
  final List<TournamentParticipantEntity> participants;
  final List<TournamentMatchEntity> matches;
  final List<TournamentMatchEntity> disputedMatches;
  final List<TournamentAuditLogEntity> auditLogs;
  final Map<String, dynamic>? lastAwardResult;
  final int selectedTab; // 0: Tournaments, 1: Participants/Payments, 2: Bracket, 3: Disputes, 4: Audit Logs & Prizes
  final String? errorMessage;
  final String? successMessage;

  const TournamentState({
    this.status = TournamentCubitStatus.initial,
    this.tournaments = const [],
    this.selectedTournament,
    this.participants = const [],
    this.matches = const [],
    this.disputedMatches = const [],
    this.auditLogs = const [],
    this.lastAwardResult,
    this.selectedTab = 0,
    this.errorMessage,
    this.successMessage,
  });

  TournamentState copyWith({
    TournamentCubitStatus? status,
    List<TournamentEntity>? tournaments,
    TournamentEntity? selectedTournament,
    bool clearSelectedTournament = false,
    List<TournamentParticipantEntity>? participants,
    List<TournamentMatchEntity>? matches,
    List<TournamentMatchEntity>? disputedMatches,
    List<TournamentAuditLogEntity>? auditLogs,
    Map<String, dynamic>? lastAwardResult,
    int? selectedTab,
    String? errorMessage,
    String? successMessage,
  }) {
    return TournamentState(
      status: status ?? this.status,
      tournaments: tournaments ?? this.tournaments,
      selectedTournament: clearSelectedTournament
          ? null
          : (selectedTournament ?? this.selectedTournament),
      participants: participants ?? this.participants,
      matches: matches ?? this.matches,
      disputedMatches: disputedMatches ?? this.disputedMatches,
      auditLogs: auditLogs ?? this.auditLogs,
      lastAwardResult: lastAwardResult ?? this.lastAwardResult,
      selectedTab: selectedTab ?? this.selectedTab,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tournaments,
        selectedTournament,
        participants,
        matches,
        disputedMatches,
        auditLogs,
        lastAwardResult,
        selectedTab,
        errorMessage,
        successMessage,
      ];
}
