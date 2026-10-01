import '../../../lounges/domain/entities/extra_entity.dart';

class OnboardingExtraPayload {
  static Map<String, dynamic> fromExtra(ExtraEntity extra) => {
    'id': extra.id,
    'name': extra.nameEn.isNotEmpty ? extra.nameEn : extra.nameAr,
    'name_ar': extra.nameAr.isNotEmpty ? extra.nameAr : extra.nameEn,
    'name_en': extra.nameEn.isNotEmpty ? extra.nameEn : extra.nameAr,
    'price': extra.price,
    'category': extra.category,
    'is_available': extra.isAvailable,
    'is_active': true,
    'stock_quantity': extra.stockQuantity,
    'track_stock': extra.trackStock,
    'min_stock_alert': extra.minStockAlert,
    'image_url': extra.imageUrl,
    'icon_key': extra.iconKey,
  };
}
