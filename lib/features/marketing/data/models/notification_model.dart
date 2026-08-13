import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    super.userId,
    required super.titleAr,
    required super.titleEn,
    required super.bodyAr,
    required super.bodyEn,
    required super.type,
    required super.createdAt,
    super.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      titleAr: json['title_ar']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      bodyAr: json['body_ar']?.toString() ?? '',
      bodyEn: json['body_en']?.toString() ?? '',
      type: _parseType(json['type']),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'],
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'booking': return NotificationType.booking;
      case 'offer': return NotificationType.offer;
      case 'loyalty': return NotificationType.loyalty;
      default: return NotificationType.system;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title_ar': titleAr,
      'title_en': titleEn,
      'body_ar': bodyAr,
      'body_en': bodyEn,
      'type': type.name,
      'metadata': metadata,
    };
  }
}
