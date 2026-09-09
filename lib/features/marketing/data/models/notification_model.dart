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
    super.isRead = false,
    required super.createdAt,
    super.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? json['notification_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      titleAr: json['title_ar']?.toString() ?? json['title']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? json['title']?.toString() ?? '',
      bodyAr: json['body_ar']?.toString() ?? json['body']?.toString() ?? '',
      bodyEn: json['body_en']?.toString() ?? json['body']?.toString() ?? '',
      type: _parseType(json['type']),
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt: json['created_at'] != null ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()) : DateTime.now(),
      metadata: json['metadata'],
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'booking': return NotificationType.booking;
      case 'offer': return NotificationType.offer;
      case 'loyalty': return NotificationType.loyalty;
      case 'kyc': return NotificationType.kyc;
      default: return NotificationType.system;
    }
  }

  Map<String, dynamic> toJson() {
    String validTypeStr;
    switch (type) {
      case NotificationType.booking:
        validTypeStr = 'booking';
        break;
      case NotificationType.offer:
        validTypeStr = 'offer';
        break;
      case NotificationType.loyalty:
        validTypeStr = 'offer';
        break;
      case NotificationType.kyc:
        validTypeStr = 'kyc';
        break;
      default:
        validTypeStr = 'system';
    }

    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'title': titleEn.isNotEmpty ? titleEn : titleAr,
      'title_ar': titleAr,
      'title_en': titleEn,
      'body': bodyEn.isNotEmpty ? bodyEn : bodyAr,
      'body_ar': bodyAr,
      'body_en': bodyEn,
      'type': validTypeStr,
      'metadata': metadata,
    };
  }
}
