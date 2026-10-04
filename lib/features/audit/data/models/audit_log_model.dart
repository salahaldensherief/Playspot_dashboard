import '../../domain/entities/audit_log_entity.dart';

class AuditLogModel extends AuditLogEntity {
  const AuditLogModel({
    required super.id,
    super.loungeId,
    required super.entityType,
    super.entityId,
    required super.action,
    super.eventCode,
    super.titleAr,
    super.titleEn,
    super.actorUserId,
    super.actorName,
    super.actorRole,
    super.severity = AuditSeverity.info,
    super.oldData,
    super.newData,
    super.reason,
    required super.createdAt,
  });

  factory AuditLogModel.fromRoomStatusJson(Map<String, dynamic> json) {
    return AuditLogModel.fromJson({
      'id': json['id'],
      'lounge_id': json['lounge_id'],
      'entity_type': 'room',
      'entity_id': json['room_id'],
      'action': json['operation'] ?? 'room_status_changed',
      'actor_user_id': json['changed_by'],
      'created_at': json['changed_at'],
      'old_data': {
        'status': json['old_status'],
        'is_available': json['old_is_available'],
      },
      'new_data': {
        'status': json['new_status'],
        'is_available': json['new_is_available'],
      },
    });
  }

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    String? actorName;
    String? actorRole;

    if (json['profiles'] is Map) {
      final profile = json['profiles'] as Map<String, dynamic>;
      actorName =
          profile['full_name']?.toString() ?? profile['name']?.toString();
      actorRole = profile['role']?.toString();
    }

    actorName ??=
        json['actor_name']?.toString() ??
        json['user_name']?.toString() ??
        json['performed_by_name']?.toString() ??
        json['full_name']?.toString();

    actorRole ??= json['actor_role']?.toString() ?? json['role']?.toString();

    Map<String, dynamic>? oldDataMap;
    if (json['old_data'] is Map) {
      oldDataMap = Map<String, dynamic>.from(json['old_data'] as Map);
    } else if (json['old_payload'] is Map) {
      oldDataMap = Map<String, dynamic>.from(json['old_payload'] as Map);
    }

    Map<String, dynamic>? newDataMap;
    if (json['new_data'] is Map) {
      newDataMap = Map<String, dynamic>.from(json['new_data'] as Map);
    } else if (json['new_payload'] is Map) {
      newDataMap = Map<String, dynamic>.from(json['new_payload'] as Map);
    } else if (json['payload'] is Map) {
      newDataMap = Map<String, dynamic>.from(json['payload'] as Map);
    } else if (json['details'] is Map) {
      newDataMap = Map<String, dynamic>.from(json['details'] as Map);
    }

    final rawEventCode = json['event_code']?.toString();
    final rawTitleAr = json['title_ar']?.toString();
    final rawTitleEn = json['title_en']?.toString();

    final rawSeverity =
        json['severity']?.toString() ??
        json['level']?.toString() ??
        json['priority']?.toString();

    final rawAction =
        json['event_code']?.toString() ??
        json['action']?.toString() ??
        json['action_type']?.toString() ??
        json['event_type']?.toString() ??
        'update';

    final rawEntityType =
        json['entity_type']?.toString() ??
        json['type']?.toString() ??
        'booking';

    final rawOccurredAt = json['occurred_at'] ?? json['created_at'];

    final rawCreatedAt = DateTime.tryParse(rawOccurredAt?.toString() ?? '');
    final id = (json['id'] ?? json['event_id'] ?? '').toString();
    if (rawCreatedAt == null || id.trim().isEmpty) {
      throw const FormatException(
        'Audit event requires identity and timestamp',
      );
    }

    return AuditLogModel(
      id: id,
      loungeId: json['lounge_id']?.toString(),
      entityType: rawEntityType,
      entityId:
          json['entity_id']?.toString() ??
          json['booking_id']?.toString() ??
          json['shift_id']?.toString() ??
          json['room_id']?.toString(),
      action: rawAction,
      eventCode: rawEventCode,
      titleAr: rawTitleAr,
      titleEn: rawTitleEn,
      actorUserId:
          json['actor_user_id']?.toString() ??
          json['performed_by']?.toString() ??
          json['user_id']?.toString(),
      actorName: actorName,
      actorRole: actorRole,
      severity: AuditSeverity.fromString(rawSeverity),
      oldData: oldDataMap,
      newData: newDataMap,
      reason: json['reason']?.toString() ?? json['notes']?.toString(),
      createdAt: rawCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lounge_id': loungeId,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'event_code': eventCode,
      'title_ar': titleAr,
      'title_en': titleEn,
      'actor_user_id': actorUserId,
      'actor_name': actorName,
      'actor_role': actorRole,
      'severity': severity.value,
      'old_data': oldData,
      'new_data': newData,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
