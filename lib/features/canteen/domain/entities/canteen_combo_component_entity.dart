import 'package:equatable/equatable.dart';

class CanteenComboComponentEntity extends Equatable {
  final String comboId;
  final String extraId;
  final int quantity;
  final String? extraNameAr;
  final String? extraNameEn;
  final double? extraPrice;
  final double? extraCostPrice;
  final String? extraImageUrl;

  const CanteenComboComponentEntity({
    required this.comboId,
    required this.extraId,
    required this.quantity,
    this.extraNameAr,
    this.extraNameEn,
    this.extraPrice,
    this.extraCostPrice,
    this.extraImageUrl,
  });

  @override
  List<Object?> get props => [
        comboId,
        extraId,
        quantity,
        extraNameAr,
        extraNameEn,
        extraPrice,
        extraCostPrice,
        extraImageUrl,
      ];
}
