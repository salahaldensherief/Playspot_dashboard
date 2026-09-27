import 'package:equatable/equatable.dart';

class ShiftAuditLogEntity extends Equatable {
  final String id;
  final String? loungeId;
  final String? shiftId;
  final String entityType; // 'shift', 'payment', 'expense', 'booking'
  final String? entityId;
  final String action; // 'insert', 'update', 'delete'
  final String? actorUserId;
  final String? actorName;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime createdAt;

  const ShiftAuditLogEntity({
    required this.id,
    this.loungeId,
    this.shiftId,
    required this.entityType,
    this.entityId,
    required this.action,
    this.actorUserId,
    this.actorName,
    this.oldData,
    this.newData,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        loungeId,
        shiftId,
        entityType,
        entityId,
        action,
        actorUserId,
        actorName,
        oldData,
        newData,
        createdAt,
      ];
}
