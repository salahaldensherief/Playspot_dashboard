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

    final rawAction = (json['action_type'] ??
            json['action'] ??
            json['event_type'] ??
            json['event'] ??
            json['type'] ??
            '')
        .toString()
        .trim();

    final rawPerformedBy = (json['performed_by'] ??
            json['user_id'] ??
            json['created_by'] ??
            json['admin_id'] ??
            '')
        .toString()
        .trim();

    final rawName = adminName ??
        json['performed_by_name']?.toString() ??
        json['user_name']?.toString() ??
        json['full_name']?.toString() ??
        json['created_by_name']?.toString();

    Map<String, dynamic>? detailsMap;
    if (json['details'] is Map<String, dynamic>) {
      detailsMap = json['details'] as Map<String, dynamic>;
    } else if (json['payload'] is Map<String, dynamic>) {
      detailsMap = json['payload'] as Map<String, dynamic>;
    } else if (json['metadata'] is Map<String, dynamic>) {
      detailsMap = json['metadata'] as Map<String, dynamic>;
    }

    return TournamentAuditLogModel(
      id: json['id']?.toString() ?? '',
      tournamentId: json['tournament_id']?.toString() ?? '',
      actionType: rawAction.isNotEmpty ? rawAction : 'tournament_updated',
      performedBy: rawPerformedBy,
      performedByName: (rawName != null && rawName.trim().isNotEmpty)
          ? rawName.trim()
          : (rawPerformedBy.isNotEmpty
              ? (rawPerformedBy.length > 8 ? rawPerformedBy.substring(0, 8) : rawPerformedBy)
              : 'النظام'),
      details: detailsMap,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
