import '../../domain/entities/app_policy_entity.dart';

class AppPolicyModel extends AppPolicyEntity {
  const AppPolicyModel({
    required super.id,
    required super.policyType,
    required super.titleAr,
    required super.titleEn,
    required super.contentAr,
    required super.contentEn,
    super.isPublished = true,
    super.updatedAt,
  });

  factory AppPolicyModel.fromJson(Map<String, dynamic> json) {
    return AppPolicyModel(
      id: json['id']?.toString() ?? '',
      policyType: json['policy_type'] as String? ?? 'terms_of_service',
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      contentAr: json['content_ar'] as String? ?? '',
      contentEn: json['content_en'] as String? ?? '',
      isPublished: json['is_published'] as bool? ?? true,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'policy_type': policyType,
      'title_ar': titleAr,
      'title_en': titleEn,
      'content_ar': contentAr,
      'content_en': contentEn,
      'is_published': isPublished,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
