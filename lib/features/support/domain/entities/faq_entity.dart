import 'package:equatable/equatable.dart';

class FaqEntity extends Equatable {
  final String id;
  final String questionAr;
  final String answerAr;
  final String questionEn;
  final String answerEn;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FaqEntity({
    required this.id,
    required this.questionAr,
    required this.answerAr,
    required this.questionEn,
    required this.answerEn,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        questionAr,
        answerAr,
        questionEn,
        answerEn,
        sortOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}
