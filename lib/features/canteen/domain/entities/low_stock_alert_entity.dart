import 'package:equatable/equatable.dart';

class LowStockAlertEntity extends Equatable {
  final String loungeId;
  final String extraId;
  final String nameAr;
  final String? nameEn;
  final String category;
  final int stockQuantity;
  final int minStockThreshold;

  const LowStockAlertEntity({
    required this.loungeId,
    required this.extraId,
    required this.nameAr,
    this.nameEn,
    required this.category,
    required this.stockQuantity,
    required this.minStockThreshold,
  });

  @override
  List<Object?> get props => [
        loungeId,
        extraId,
        nameAr,
        nameEn,
        category,
        stockQuantity,
        minStockThreshold,
      ];
}
