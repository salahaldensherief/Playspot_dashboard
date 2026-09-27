import '../../domain/entities/tournament_prize_reward_entity.dart';

class TournamentPrizeRewardModel extends TournamentPrizeRewardEntity {
  const TournamentPrizeRewardModel({
    required super.id,
    required super.prizeId,
    required super.type,
    super.title,
    super.titleAr,
    super.titleEn,
    super.description,
    super.descriptionAr,
    super.descriptionEn,
    super.value,
    super.currency,
    super.metadata,
    super.deliveryStatus,
    super.deliveredAt,
    super.createdAt,
  });

  factory TournamentPrizeRewardModel.fromJson(Map<String, dynamic> json) {
    double? parsedValue;
    if (json['value'] != null) {
      if (json['value'] is num) {
        parsedValue = (json['value'] as num).toDouble();
      } else if (json['value'] is String) {
        parsedValue = double.tryParse(json['value'] as String);
      }
    }

    Map<String, dynamic>? meta;
    if (json['metadata'] != null && json['metadata'] is Map) {
      meta = Map<String, dynamic>.from(json['metadata'] as Map);
    }

    return TournamentPrizeRewardModel(
      id: json['id'] as String? ?? '',
      prizeId: json['prize_id'] as String? ?? '',
      type: TournamentPrizeType.fromString(json['type'] as String?),
      title: json['title'] as String?,
      titleAr: json['title_ar'] as String?,
      titleEn: json['title_en'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      value: parsedValue,
      currency: json['currency'] as String?,
      metadata: meta,
      deliveryStatus: json['delivery_status'] as String? ?? json['status'] as String? ?? 'pending',
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'].toString())
          : (json['delivery_time'] != null
              ? DateTime.tryParse(json['delivery_time'].toString())
              : null),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && !id.startsWith('temp_')) 'id': id,
      if (prizeId.isNotEmpty && !prizeId.startsWith('temp_')) 'prize_id': prizeId,
      'reward_type': type.toDbString(),
      if (titleAr != null) 'title_ar': titleAr,
      if (titleEn != null) 'title_en': titleEn,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      if (descriptionEn != null) 'description_en': descriptionEn,
      if (value != null) 'amount': value,
      if (currency != null) 'currency': currency,
      if (metadata != null) 'metadata': metadata,
      'is_delivered': deliveryStatus == 'delivered' || deliveryStatus == 'true',
      if (deliveredAt != null) 'delivered_at': deliveredAt!.toIso8601String(),
    };
  }

  factory TournamentPrizeRewardModel.fromEntity(TournamentPrizeRewardEntity entity) {
    return TournamentPrizeRewardModel(
      id: entity.id,
      prizeId: entity.prizeId,
      type: entity.type,
      title: entity.title,
      titleAr: entity.titleAr,
      titleEn: entity.titleEn,
      description: entity.description,
      descriptionAr: entity.descriptionAr,
      descriptionEn: entity.descriptionEn,
      value: entity.value,
      currency: entity.currency,
      metadata: entity.metadata,
      deliveryStatus: entity.deliveryStatus,
      deliveredAt: entity.deliveredAt,
      createdAt: entity.createdAt,
    );
  }
}
