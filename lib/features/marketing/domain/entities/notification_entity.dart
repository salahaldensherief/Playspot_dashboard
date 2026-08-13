import 'package:equatable/equatable.dart';

enum NotificationType { booking, offer, loyalty, system }

class NotificationEntity extends Equatable {
  final String id;
  final String? userId;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final NotificationType type;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const NotificationEntity({
    required this.id,
    this.userId,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.type,
    required this.createdAt,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, userId, titleAr, titleEn, bodyAr, bodyEn, type, createdAt, metadata];
}
