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
    super.createdBy,
    required super.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id']?.toString() ?? '',
      targetAudience: switch (json['target_audience']?.toString()) {
        'owners' => 'lounge_owners',
        'specific_venue' => 'specific_lounge',
        final value? => value,
        null => 'all',
      },
      targetLoungeId:
          (json['target_venue_id'] ?? json['target_lounge_id'])?.toString(),
      targetLoungeName: json['target_lounge_name']?.toString(),
      titleAr: json['title_ar']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      bodyAr: json['body_ar']?.toString() ?? '',
      bodyEn: json['body_en']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'target_audience': switch (targetAudience) {
        'lounge_owners' => 'owners',
        'specific_lounge' => 'specific_venue',
        final value => value,
      },
      'target_venue_id': targetLoungeId,
      'title_ar': titleAr,
      'title_en': titleEn,
      'body_ar': bodyAr,
      'body_en': bodyEn,
      'type': type,
      'is_active': isActive,
      if (createdBy != null && createdBy!.isNotEmpty) 'created_by': createdBy,
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
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }
}
