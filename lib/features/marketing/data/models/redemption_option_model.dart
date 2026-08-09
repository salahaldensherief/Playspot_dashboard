import '../../domain/entities/redemption_option_entity.dart';

class RedemptionOptionModel extends RedemptionOptionEntity {
  const RedemptionOptionModel({
    required super.id,
    required super.titleAr,
    required super.titleEn,
    required super.descriptionAr,
    required super.descriptionEn,
    required super.pointsCost,
    required super.rewardType,
    required super.rewardValue,
  });

  factory RedemptionOptionModel.fromJson(Map<String, dynamic> json) {
    return RedemptionOptionModel(
      id: json['id']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      descriptionAr: json['description_ar']?.toString() ?? '',
      descriptionEn: json['description_en']?.toString() ?? '',
      pointsCost: (json['points_cost'] as num?)?.toInt() ?? 0,
      rewardType: json['reward_type']?.toString() ?? '',
      rewardValue: (json['reward_value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_ar': titleAr,
      'title_en': titleEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'points_cost': pointsCost,
      'reward_type': rewardType,
      'reward_value': rewardValue,
    };
  }
}
