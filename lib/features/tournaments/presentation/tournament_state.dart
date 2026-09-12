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
  final int auditLogsPage;
  final int auditLogsPageSize;
  final int totalAuditLogsCount;
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
    this.auditLogsPage = 1,
    this.auditLogsPageSize = 50,
    this.totalAuditLogsCount = 0,
    this.lastAwardResult,
    this.selectedTab = 0,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasNextAuditLogsPage => auditLogsPage * auditLogsPageSize < totalAuditLogsCount;
  bool get hasPreviousAuditLogsPage => auditLogsPage > 1;
  int get totalAuditLogsPages => auditLogsPageSize > 0 ? (totalAuditLogsCount / auditLogsPageSize).ceil() : 0;

  TournamentState copyWith({
    TournamentCubitStatus? status,
    List<TournamentEntity>? tournaments,
    TournamentEntity? selectedTournament,
    bool clearSelectedTournament = false,
    List<TournamentParticipantEntity>? participants,
    List<TournamentMatchEntity>? matches,
    List<TournamentMatchEntity>? disputedMatches,
    List<TournamentAuditLogEntity>? auditLogs,
    int? auditLogsPage,
    int? auditLogsPageSize,
    int? totalAuditLogsCount,
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
      auditLogsPage: auditLogsPage ?? this.auditLogsPage,
      auditLogsPageSize: auditLogsPageSize ?? this.auditLogsPageSize,
      totalAuditLogsCount: totalAuditLogsCount ?? this.totalAuditLogsCount,
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
        auditLogsPage,
        auditLogsPageSize,
        totalAuditLogsCount,
        lastAwardResult,
        selectedTab,
        errorMessage,
        successMessage,
      ];
}
