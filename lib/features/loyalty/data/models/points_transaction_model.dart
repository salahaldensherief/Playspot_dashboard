import '../../domain/entities/points_transaction_entity.dart';

class PointsTransactionModel extends PointsTransactionEntity {
  const PointsTransactionModel({
    required super.id,
    required super.userId,
    required super.pointsDelta,
    required super.type,
    super.sourceType,
    super.sourceId,
    super.reason,
    required super.createdAt,
  });

  factory PointsTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointsTransactionModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      pointsDelta: (json['points_delta'] as num?)?.toInt() ?? (json['points'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? json['source_type']?.toString() ?? 'unknown',
      sourceType: json['source_type']?.toString(),
      sourceId: json['source_id']?.toString(),
      reason: json['reason']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points_delta': pointsDelta,
      'type': type,
      'source_type': sourceType,
      'source_id': sourceId,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
