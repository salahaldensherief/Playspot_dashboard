import '../../domain/entities/loyalty_level_entity.dart';

class LoyaltyLevelModel extends LoyaltyLevelEntity {
  const LoyaltyLevelModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.minPoints,
    required super.multiplier,
    required super.userCount,
    super.colorHex = '#3B82F6',
  });

  factory LoyaltyLevelModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyLevelModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      minPoints: (json['min_points'] as num?)?.toInt() ?? 0,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      userCount: (json['user_count'] as num?)?.toInt() ?? (json['users_count'] as num?)?.toInt() ?? 0,
      colorHex: json['color_hex']?.toString() ?? '#3B82F6',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'min_points': minPoints,
      'multiplier': multiplier,
      'user_count': userCount,
      'color_hex': colorHex,
    };
  }
}
