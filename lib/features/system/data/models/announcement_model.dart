import '../../domain/entities/announcement_entity.dart';

class AnnouncementModel extends AnnouncementEntity {
  const AnnouncementModel({
    required super.id,
    required super.targetAudience,
    super.targetLoungeId,
    super.targetLoungeName,
    required super.titleAr,
    required super.titleEn,
    required super.bodyAr,
    required super.bodyEn,
    required super.type,
    super.isActive = true,
    required super.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id']?.toString() ?? '',
      targetAudience: json['target_audience']?.toString() ?? 'all',
      targetLoungeId: json['target_lounge_id']?.toString(),
      targetLoungeName: json['target_lounge_name']?.toString(),
      titleAr: json['title_ar']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      bodyAr: json['body_ar']?.toString() ?? '',
      bodyEn: json['body_en']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'target_audience': targetAudience,
      'target_lounge_id': targetLoungeId,
      'target_lounge_name': targetLoungeName,
      'title_ar': titleAr,
      'title_en': titleEn,
      'body_ar': bodyAr,
      'body_en': bodyEn,
      'type': type,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AnnouncementModel.fromEntity(AnnouncementEntity entity) {
    return AnnouncementModel(
      id: entity.id,
      targetAudience: entity.targetAudience,
      targetLoungeId: entity.targetLoungeId,
      targetLoungeName: entity.targetLoungeName,
      titleAr: entity.titleAr,
      titleEn: entity.titleEn,
      bodyAr: entity.bodyAr,
      bodyEn: entity.bodyEn,
      type: entity.type,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}
