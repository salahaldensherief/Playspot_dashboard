import '../../domain/entities/promo_entity.dart';

class PromoModel extends PromoEntity {
  const PromoModel({
    required super.id,
    required super.titleAr,
    required super.titleEn,
    required super.tagAr,
    required super.tagEn,
    required super.hexColors,
    required super.iconKey,
    super.imageUrl,
    super.deepLink,
    super.loungeId,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      id: json['id']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      tagAr: json['tag_ar']?.toString() ?? '',
      tagEn: json['tag_en']?.toString() ?? '',
      hexColors: List<String>.from(json['colors'] ?? []),
      iconKey: json['icon_key']?.toString() ?? '',
      imageUrl: json['image_url'],
      deepLink: json['deep_link'],
      loungeId: json['lounge_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_ar': titleAr,
      'title_en': titleEn,
      'tag_ar': tagAr,
      'tag_en': tagEn,
      'colors': hexColors,
      'icon_key': iconKey,
      'image_url': imageUrl,
      'deep_link': deepLink,
      'lounge_id': loungeId,
    };
  }
}
