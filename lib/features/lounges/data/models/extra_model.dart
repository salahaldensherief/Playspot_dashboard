import '../../domain/entities/extra_entity.dart';

class ExtraModel extends ExtraEntity {
  const ExtraModel({
    required super.id,
    required super.loungeId,
    required super.nameAr,
    required super.nameEn,
    super.name,
    required super.price,
    required super.category,
    super.iconKey,
    super.isOutOfStock,
    super.imageUrl,
    super.stockQuantity,
    super.trackStock,
    super.minStockAlert,
  });

  factory ExtraModel.fromJson(Map<String, dynamic> json) {
    return ExtraModel(
      id: json['id']?.toString() ?? '',
      loungeId: json['lounge_id']?.toString() ?? '',
      nameAr: (json['name_ar'] ?? json['name'])?.toString() ?? '',
      nameEn: (json['name_en'] ?? json['name'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? 'Others',
      iconKey: json['icon_key']?.toString(),
      // The backend uses 'is_available', so we invert it for 'isOutOfStock'
      isOutOfStock: json['is_available'] == false,
      imageUrl: json['image_url']?.toString(),
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      trackStock: json['track_stock'] ?? false,
      minStockAlert: (json['min_stock_alert'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lounge_id': loungeId,
      'name': nameEn,
      'name_ar': nameAr,
      'name_en': nameEn,
      'price': price,
      'category': category,
      'icon_key': iconKey,
      'is_available': !isOutOfStock,
      'image_url': imageUrl,
      'stock_quantity': stockQuantity,
      'track_stock': trackStock,
      'min_stock_alert': minStockAlert,
    };
  }
}
