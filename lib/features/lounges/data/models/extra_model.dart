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
    String rawCategory = (json['category']?.toString() ?? 'other').toLowerCase().trim();
    if (rawCategory == 'others') rawCategory = 'other';

    final rawImage = json['image_url']?.toString();
    final imageUrl = (rawImage != null && rawImage.trim().isNotEmpty) ? rawImage.trim() : null;

    return ExtraModel(
      id: json['id']?.toString() ?? '',
      loungeId: json['lounge_id']?.toString() ?? '',
      nameAr: (json['name_ar'] ?? json['name'])?.toString() ?? '',
      nameEn: (json['name_en'] ?? json['name'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: rawCategory,
      iconKey: json['icon_key']?.toString(),
      // The backend uses 'is_available', so we invert it for 'isOutOfStock'
      isOutOfStock: json['is_available'] == false,
      imageUrl: imageUrl,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      trackStock: json['track_stock'] ?? false,
      minStockAlert: (json['min_stock_alert'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    String validCategory = category.toLowerCase().trim();
    if (validCategory == 'others') validCategory = 'other';

    return {
      'id': id,
      'lounge_id': loungeId,
      'name': nameEn.isEmpty ? (nameAr.isEmpty ? 'Extra Item' : nameAr) : nameEn,
      'name_ar': nameAr,
      'name_en': nameEn,
      'price': price,
      'category': validCategory,
      'icon_key': iconKey,
      'is_available': !isOutOfStock,
      'stock_quantity': stockQuantity,
      'track_stock': trackStock,
      'min_stock_alert': minStockAlert,
    };
  }
}
