import '../../domain/entities/loyalty_task_entity.dart';

class LoyaltyTaskModel extends LoyaltyTaskEntity {
  const LoyaltyTaskModel({
    required super.id,
    required super.titleAr,
    required super.titleEn,
    required super.descriptionAr,
    required super.descriptionEn,
    required super.pointsReward,
    required super.completedCount,
    required super.isActive,
  });

  factory LoyaltyTaskModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyTaskModel(
      id: json['id']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? json['name_ar']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? json['name_en']?.toString() ?? '',
      descriptionAr: json['description_ar']?.toString() ?? '',
      descriptionEn: json['description_en']?.toString() ?? '',
      pointsReward: (json['points_reward'] as num?)?.toInt() ?? (json['points'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_ar': titleAr,
      'title_en': titleEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'points_reward': pointsReward,
      'completed_count': completedCount,
      'is_active': isActive,
    };
  }
}
