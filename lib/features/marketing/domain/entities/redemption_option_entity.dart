import 'package:equatable/equatable.dart';

class RedemptionOptionEntity extends Equatable {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final int pointsCost;
  final String rewardType;
  final double rewardValue;

  const RedemptionOptionEntity({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.pointsCost,
    required this.rewardType,
    required this.rewardValue,
  });

  @override
  List<Object?> get props => [
        id,
        titleAr,
        titleEn,
        descriptionAr,
        descriptionEn,
        pointsCost,
        rewardType,
        rewardValue,
      ];
}
