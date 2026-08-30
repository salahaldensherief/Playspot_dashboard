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
    // This print will help us see the exact keys coming from the database
    // ignore: avoid_print
    print('DEBUG: Permission JSON: $json');
    
    return PermissionItemModel(
      key: (json['permission_key'] ?? json['out_permission_key'] ?? json['key'] ?? json['id'] ?? '').toString(),
      nameAr: (json['name_ar'] ?? json['out_name_ar'] ?? json['permission_name_ar'] ?? json['name'] ?? '').toString(),
      nameEn: (json['name_en'] ?? json['out_name_en'] ?? json['permission_name_en'] ?? json['name'] ?? '').toString(),
      category: (json['category'] ?? json['out_category'] ?? json['permission_category'] ?? 'General').toString(),
      descriptionAr: (json['description_ar'] ?? json['out_description_ar'] ?? json['description'] ?? '').toString(),
      descriptionEn: (json['description_en'] ?? json['out_description_en'] ?? json['description'] ?? '').toString(),
      isEnabled: json['is_enabled'] ?? json['out_is_enabled'] ?? false,
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
