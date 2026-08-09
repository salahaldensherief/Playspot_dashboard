import 'package:equatable/equatable.dart';

class PromoEntity extends Equatable {
  final String id;
  final String titleAr;
  final String titleEn;
  final String tagAr;
  final String tagEn;
  final List<String> hexColors;
  final String iconKey;
  final String? imageUrl;
  final String? deepLink;

  const PromoEntity({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.tagAr,
    required this.tagEn,
    required this.hexColors,
    required this.iconKey,
    this.imageUrl,
    this.deepLink,
  });

  @override
  List<Object?> get props => [id, titleAr, titleEn, tagAr, tagEn, hexColors, iconKey, imageUrl, deepLink];
}
