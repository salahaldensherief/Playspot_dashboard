import 'package:equatable/equatable.dart';

class AppPolicyEntity extends Equatable {
  final String id;
  final String policyType; // 'terms_of_service', 'privacy_policy', 'refund_policy'
  final String titleAr;
  final String titleEn;
  final String contentAr;
  final String contentEn;
  final bool isPublished;
  final DateTime? updatedAt;

  const AppPolicyEntity({
    required this.id,
    required this.policyType,
    required this.titleAr,
    required this.titleEn,
    required this.contentAr,
    required this.contentEn,
    this.isPublished = true,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        policyType,
        titleAr,
        titleEn,
        contentAr,
        contentEn,
        isPublished,
        updatedAt,
      ];
}
