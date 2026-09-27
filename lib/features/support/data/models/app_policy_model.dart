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
    final policyKey =
        json['policy_key']?.toString() ??
        json['policy_type']?.toString() ??
        json['id']?.toString() ??
        '';

    return AppPolicyModel(
      id: policyKey,
      policyType: policyKey,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      contentAr: json['content_ar'] as String? ?? '',
      contentEn: json['content_en'] as String? ?? '',
      isPublished: json['is_published'] as bool? ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final key = policyType.trim().isNotEmpty ? policyType.trim() : id.trim();
    return {
      'policy_key': key,
      'title_ar': titleAr,
      'title_en': titleEn,
      'content_ar': contentAr,
      'content_en': contentEn,
      'is_published': isPublished,
    };
  }
}
