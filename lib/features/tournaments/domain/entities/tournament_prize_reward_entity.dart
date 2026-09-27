import 'package:equatable/equatable.dart';

enum TournamentPrizeType {
  trophy,
  cash,
  points,
  voucher,
  custom;

  static TournamentPrizeType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'trophy':
        return TournamentPrizeType.trophy;
      case 'cash':
        return TournamentPrizeType.cash;
      case 'points':
        return TournamentPrizeType.points;
      case 'voucher':
        return TournamentPrizeType.voucher;
      case 'custom':
      default:
        return TournamentPrizeType.custom;
    }
  }

  String toDbString() => name;
}

class TournamentPrizeRewardEntity extends Equatable {
  final String id;
  final String prizeId;
  final TournamentPrizeType type;
  final String? title;
  final String? titleAr;
  final String? titleEn;
  final String? description;
  final String? descriptionAr;
  final String? descriptionEn;
  final double? value;
  final String? currency;
  final Map<String, dynamic>? metadata;
  final String? deliveryStatus;
  final DateTime? deliveredAt;
  final DateTime? createdAt;

  const TournamentPrizeRewardEntity({
    required this.id,
    required this.prizeId,
    required this.type,
    this.title,
    this.titleAr,
    this.titleEn,
    this.description,
    this.descriptionAr,
    this.descriptionEn,
    this.value,
    this.currency,
    this.metadata,
    this.deliveryStatus = 'pending',
    this.deliveredAt,
    this.createdAt,
  });

  bool get isTrophy => type == TournamentPrizeType.trophy;
  bool get isCash => type == TournamentPrizeType.cash;
  bool get isPoints => type == TournamentPrizeType.points;
  bool get isVoucher => type == TournamentPrizeType.voucher;
  bool get isCustom => type == TournamentPrizeType.custom;

  TournamentPrizeRewardEntity copyWith({
    String? id,
    String? prizeId,
    TournamentPrizeType? type,
    String? title,
    String? titleAr,
    String? titleEn,
    String? description,
    String? descriptionAr,
    String? descriptionEn,
    double? value,
    String? currency,
    Map<String, dynamic>? metadata,
    String? deliveryStatus,
    DateTime? deliveredAt,
    DateTime? createdAt,
  }) {
    return TournamentPrizeRewardEntity(
      id: id ?? this.id,
      prizeId: prizeId ?? this.prizeId,
      type: type ?? this.type,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      value: value ?? this.value,
      currency: currency ?? this.currency,
      metadata: metadata ?? this.metadata,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        prizeId,
        type,
        title,
        titleAr,
        titleEn,
        description,
        descriptionAr,
        descriptionEn,
        value,
        currency,
        metadata,
        deliveryStatus,
        deliveredAt,
        createdAt,
      ];
}
