import '../../domain/entities/canteen_combo_component_entity.dart';

class CanteenComboComponentModel extends CanteenComboComponentEntity {
  const CanteenComboComponentModel({
    required super.comboId,
    required super.extraId,
    required super.quantity,
    super.extraNameAr,
    super.extraNameEn,
    super.extraPrice,
    super.extraCostPrice,
    super.extraImageUrl,
  });

  factory CanteenComboComponentModel.fromJson(Map<String, dynamic> json) {
    final extra = json['extras'] ?? json['extra'];
    String? nameAr;
    String? nameEn;
    double? price;
    double? costPrice;
    String? imageUrl;

    if (extra is Map) {
      nameAr = extra['name_ar']?.toString();
      nameEn = extra['name_en']?.toString();
      price = (extra['price'] as num?)?.toDouble();
      costPrice = (extra['cost_price'] as num?)?.toDouble();
      imageUrl = extra['image_url']?.toString();
    }

    return CanteenComboComponentModel(
      comboId: (json['combo_id'] ?? '').toString(),
      extraId: (json['extra_id'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      extraNameAr:
          nameAr ??
          json['extra_name_ar']?.toString() ??
          json['name_ar']?.toString(),
      extraNameEn:
          nameEn ??
          json['extra_name_en']?.toString() ??
          json['name_en']?.toString(),
      extraPrice:
          price ??
          (json['extra_price'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble(),
      extraCostPrice:
          costPrice ??
          (json['extra_cost_price'] as num?)?.toDouble() ??
          (json['cost_price'] as num?)?.toDouble(),
      extraImageUrl:
          imageUrl ??
          json['extra_image_url']?.toString() ??
          json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combo_id': comboId,
      'extra_id': extraId,
      'quantity': quantity,
    };
  }
}
