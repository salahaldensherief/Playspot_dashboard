import '../../domain/entities/tournament_audit_log_entity.dart';

class TournamentAuditLogModel extends TournamentAuditLogEntity {
  const TournamentAuditLogModel({
    required super.id,
    required super.tournamentId,
    required super.actionType,
    required super.performedBy,
    super.performedByName,
    super.details,
    required super.createdAt,
  });

  factory TournamentAuditLogModel.fromJson(Map<String, dynamic> json) {
    String? adminName;
    if (json['profiles'] != null && json['profiles'] is Map) {
      adminName = json['profiles']['full_name'] as String?;
    }

    return TournamentAuditLogModel(
      id: json['id'] as String? ?? '',
      tournamentId: json['tournament_id'] as String? ?? '',
      actionType: json['action_type'] as String? ?? '',
      performedBy: json['performed_by'] as String? ?? '',
      performedByName: adminName ?? json['performed_by_name'] as String?,
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
