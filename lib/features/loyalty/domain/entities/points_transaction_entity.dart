import 'package:equatable/equatable.dart';

class PointsTransactionEntity extends Equatable {
  final String id;
  final String userId;
  final int pointsDelta;
  final String type;
  final String? sourceType;
  final String? sourceId;
  final String? reason;
  final DateTime createdAt;

  const PointsTransactionEntity({
    required this.id,
    required this.userId,
    required this.pointsDelta,
    required this.type,
    this.sourceType,
    this.sourceId,
    this.reason,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, pointsDelta, type, sourceType, sourceId, reason, createdAt];
}
