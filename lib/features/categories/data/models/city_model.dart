import '../../domain/entities/city_entity.dart';

class CityModel extends CityEntity {
  const CityModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    super.isActive = true,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_ar': nameAr,
      'name_en': nameEn,
      'is_active': isActive,
    };
  }
}
