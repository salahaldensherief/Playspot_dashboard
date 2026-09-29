import 'package:equatable/equatable.dart';

enum AuditSeverity {
  critical,
  warning,
  info;

  static AuditSeverity fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'critical':
      case 'danger':
      case 'error':
      case 'high':
        return AuditSeverity.critical;
      case 'warning':
      case 'medium':
      case 'warn':
        return AuditSeverity.warning;
      case 'info':
      case 'low':
      default:
        return AuditSeverity.info;
    }
  }

  String get value {
    switch (this) {
      case AuditSeverity.critical:
        return 'critical';
      case AuditSeverity.warning:
        return 'warning';
      case AuditSeverity.info:
        return 'info';
    }
  }
}

class AuditFieldChange extends Equatable {
  final String fieldKey;
  final String labelKey;
  final dynamic oldValue;
  final dynamic newValue;

  const AuditFieldChange({
    required this.fieldKey,
    required this.labelKey,
    this.oldValue,
    this.newValue,
  });

  @override
  List<Object?> get props => [fieldKey, labelKey, oldValue, newValue];
}

class AuditLogEntity extends Equatable {
  final String id;
  final String? loungeId;
  final String entityType;
  final String? entityId;
  final String action;
  final String? eventCode;
  final String? titleAr;
  final String? titleEn;
  final String? actorUserId;
  final String? actorName;
  final String? actorRole;
  final AuditSeverity severity;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? reason;
  final DateTime createdAt;

  const AuditLogEntity({
    required this.id,
    this.loungeId,
    required this.entityType,
    this.entityId,
    required this.action,
    this.eventCode,
    this.titleAr,
    this.titleEn,
    this.actorUserId,
    this.actorName,
    this.actorRole,
    this.severity = AuditSeverity.info,
    this.oldData,
    this.newData,
    this.reason,
    required this.createdAt,
  });

  /// Computes individual field changes between `oldData` and `newData`.
  List<AuditFieldChange> get changes {
    final List<AuditFieldChange> list = [];
    final oldMap = oldData ?? {};
    final newMap = newData ?? {};

    final allKeys = {...oldMap.keys, ...newMap.keys};

    for (final key in allKeys) {
      if (key == 'updated_at' || key == 'id' || key == 'created_at') continue;
      final oldVal = oldMap[key];
      final newVal = newMap[key];

      if (oldVal != newVal) {
        list.add(
          AuditFieldChange(
            fieldKey: key,
            labelKey: key,
            oldValue: oldVal,
            newValue: newVal,
          ),
        );
      }
    }
    return list;
  }

  @override
  List<Object?> get props => [
        id,
        loungeId,
        entityType,
        entityId,
        action,
        eventCode,
        titleAr,
        titleEn,
        actorUserId,
        actorName,
        actorRole,
        severity,
        oldData,
        newData,
        reason,
        createdAt,
      ];
}

class AuditLogPaginatedResult extends Equatable {
  final List<AuditLogEntity> logs;
  final bool hasMore;
  final String? nextCursorId;
  final DateTime? nextCursorCreatedAt;

  const AuditLogPaginatedResult({
    required this.logs,
    required this.hasMore,
    this.nextCursorId,
    this.nextCursorCreatedAt,
  });

  @override
  List<Object?> get props => [
        logs,
        hasMore,
        nextCursorId,
        nextCursorCreatedAt,
      ];
}
