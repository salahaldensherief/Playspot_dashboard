import 'package:equatable/equatable.dart';

class TournamentAuditLogEntity extends Equatable {
  final String id;
  final String tournamentId;
  final String actionType;
  final String performedBy;
  final String? performedByName;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  const TournamentAuditLogEntity({
    required this.id,
    required this.tournamentId,
    required this.actionType,
    required this.performedBy,
    this.performedByName,
    this.details,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        actionType,
        performedBy,
        performedByName,
        details,
        createdAt,
      ];
}
