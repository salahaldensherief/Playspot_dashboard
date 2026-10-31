import '../../domain/entities/low_stock_alert_entity.dart';

class LowStockAlertModel extends LowStockAlertEntity {
  const LowStockAlertModel({
    required super.loungeId,
    required super.extraId,
    required super.nameAr,
    super.nameEn,
    required super.category,
    required super.stockQuantity,
    required super.minStockThreshold,
  });

  factory LowStockAlertModel.fromJson(Map<String, dynamic> json) {
    return LowStockAlertModel(
      loungeId: (json['lounge_id'] ?? '').toString(),
      extraId: (json['extra_id'] ?? '').toString(),
      nameAr: (json['name_ar'] ?? '').toString(),
      nameEn: json['name_en']?.toString(),
      category: (json['category'] ?? '').toString(),
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      minStockThreshold: (json['min_stock_threshold'] as num?)?.toInt() ?? 5,
    );
  }
}
