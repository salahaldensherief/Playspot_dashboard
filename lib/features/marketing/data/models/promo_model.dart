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
    super.roomId,
    super.expiresAt,
    super.tag,
    super.isRoomSpecific = false,
    super.targetAudience = 'all',
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image_url']?.toString();
    final imageUrl = (rawImage != null && rawImage.trim().isNotEmpty) ? rawImage.trim() : null;

    return PromoModel(
      id: json['id']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      tagAr: json['tag_ar']?.toString() ?? '',
      tagEn: json['tag_en']?.toString() ?? '',
      hexColors: List<String>.from(json['colors'] ?? []),
      iconKey: json['icon_key']?.toString() ?? '',
      imageUrl: imageUrl,
      deepLink: json['deep_link'],
      loungeId: json['lounge_id']?.toString(),
      roomId: json['room_id']?.toString(),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      tag: json['tag']?.toString(),
      isRoomSpecific: json['is_room_specific'] ?? false,
      targetAudience: json['target_audience']?.toString() ?? 'all',
    );
  }

  Map<String, dynamic> toJson() {
    final validColors = hexColors.length >= 2 ? hexColors : ['#1E88E5', '#1565C0'];
    final title = titleEn.isNotEmpty ? titleEn : (titleAr.isNotEmpty ? titleAr : 'Special Offer');

    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'title_ar': titleAr,
      'title_en': titleEn,
      'tag_ar': tagAr,
      'tag_en': tagEn,
      'colors': validColors,
      'icon_key': iconKey.isNotEmpty ? iconKey : 'local_offer',
      'image_url': imageUrl,
      'deep_link': deepLink,
      'lounge_id': (loungeId != null && loungeId!.isNotEmpty) ? loungeId : null,
      'room_id': (roomId != null && roomId!.isNotEmpty) ? roomId : null,
      'expires_at': expiresAt?.toIso8601String(),
      'tag': tag ?? (tagAr.isNotEmpty ? tagAr : tagEn),
      'is_room_specific': isRoomSpecific,
      'target_audience': targetAudience,
    };
  }
}
