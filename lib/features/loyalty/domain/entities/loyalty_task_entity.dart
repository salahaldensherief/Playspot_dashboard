import 'package:equatable/equatable.dart';

class LoyaltyTaskEntity extends Equatable {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final int pointsReward;
  final int completedCount;
  final bool isActive;

  const LoyaltyTaskEntity({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.pointsReward,
    required this.completedCount,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        titleAr,
        titleEn,
        descriptionAr,
        descriptionEn,
        pointsReward,
        completedCount,
        isActive,
      ];
}
