import 'package:equatable/equatable.dart';

class LoyaltyLevelEntity extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final int minPoints;
  final double multiplier;
  final int userCount;
  final String colorHex;

  const LoyaltyLevelEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.minPoints,
    required this.multiplier,
    required this.userCount,
    this.colorHex = '#3B82F6',
  });

  @override
  List<Object?> get props => [
        id,
        nameAr,
        nameEn,
        minPoints,
        multiplier,
        userCount,
        colorHex,
      ];
}
