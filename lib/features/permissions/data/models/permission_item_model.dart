import '../../domain/entities/permission_item_entity.dart';

class PermissionItemModel extends PermissionItemEntity {
  const PermissionItemModel({
    required super.key,
    required super.nameAr,
    required super.nameEn,
    required super.category,
    required super.descriptionAr,
    required super.descriptionEn,
    required super.isEnabled,
  });

  factory PermissionItemModel.fromJson(Map<String, dynamic> json) {
    return PermissionItemModel(
      key: json['permission_key'] ?? '',
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'] ?? '',
      category: json['category'] ?? '',
      descriptionAr: json['description_ar'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      isEnabled: json['is_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'permission_key': key,
      'name_ar': nameAr,
      'name_en': nameEn,
      'category': category,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'is_enabled': isEnabled,
    };
  }
}
