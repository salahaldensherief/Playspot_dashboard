import '../../domain/entities/shift_audit_log_entity.dart';

class ShiftAuditLogModel extends ShiftAuditLogEntity {
  const ShiftAuditLogModel({
    required super.id,
    super.loungeId,
    super.shiftId,
    required super.entityType,
    super.entityId,
    required super.action,
    super.actorUserId,
    super.actorName,
    super.oldData,
    super.newData,
    required super.createdAt,
  });

  factory ShiftAuditLogModel.fromJson(Map<String, dynamic> json) {
    return ShiftAuditLogModel(
      id: (json['id'] ?? '').toString(),
      loungeId: json['lounge_id']?.toString(),
      shiftId: json['shift_id']?.toString(),
      entityType: (json['entity_type'] ?? 'shift').toString(),
      entityId: json['entity_id']?.toString(),
      action: (json['action'] ?? 'insert').toString(),
      actorUserId: json['actor_user_id']?.toString(),
      actorName: json['profiles']?['full_name']?.toString() ?? json['actor_name']?.toString(),
      oldData: json['old_data'] is Map ? Map<String, dynamic>.from(json['old_data'] as Map) : null,
      newData: json['new_data'] is Map ? Map<String, dynamic>.from(json['new_data'] as Map) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    );
  }
}
