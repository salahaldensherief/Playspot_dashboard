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

    final String fallbackTitle = json['title']?.toString() ?? '';
    final String fallbackTag = json['tag']?.toString() ?? '';

    final String titleAr = (json['title_ar'] != null && json['title_ar'].toString().trim().isNotEmpty)
        ? json['title_ar'].toString().trim()
        : fallbackTitle;

    final String titleEn = (json['title_en'] != null && json['title_en'].toString().trim().isNotEmpty)
        ? json['title_en'].toString().trim()
        : fallbackTitle;

    final String tagAr = (json['tag_ar'] != null && json['tag_ar'].toString().trim().isNotEmpty)
        ? json['tag_ar'].toString().trim()
        : fallbackTag;

    final String tagEn = (json['tag_en'] != null && json['tag_en'].toString().trim().isNotEmpty)
        ? json['tag_en'].toString().trim()
        : fallbackTag;

    return PromoModel(
      id: json['id']?.toString() ?? '',
      titleAr: titleAr,
      titleEn: titleEn,
      tagAr: tagAr,
      tagEn: tagEn,
      hexColors: json['colors'] is List ? List<String>.from(json['colors']) : <String>[],
      iconKey: json['icon_key']?.toString() ?? 'Flash',
      imageUrl: imageUrl,
      deepLink: json['deep_link']?.toString(),
      loungeId: json['lounge_id']?.toString(),
      roomId: json['room_id']?.toString(),
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
      tag: fallbackTag.isNotEmpty ? fallbackTag : tagAr,
      isRoomSpecific: json['is_room_specific'] == true,
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
