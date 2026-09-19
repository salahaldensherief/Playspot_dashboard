import '../../domain/entities/faq_entity.dart';

class FaqModel extends FaqEntity {
  const FaqModel({
    required super.id,
    required super.questionAr,
    required super.answerAr,
    required super.questionEn,
    required super.answerEn,
    super.sortOrder = 0,
    super.isActive = true,
    super.createdAt,
    super.updatedAt,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id']?.toString() ?? '',
      questionAr: json['question_ar'] as String? ?? '',
      answerAr: json['answer_ar'] as String? ?? '',
      questionEn: json['question_en'] as String? ?? '',
      answerEn: json['answer_en'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'question_ar': questionAr,
      'answer_ar': answerAr,
      'question_en': questionEn,
      'answer_en': answerEn,
      'sort_order': sortOrder,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
