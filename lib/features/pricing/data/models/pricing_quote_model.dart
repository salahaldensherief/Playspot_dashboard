import '../../domain/entities/pricing_quote_entity.dart';

class PricingSegmentModel extends PricingSegmentEntity {
  const PricingSegmentModel({
    required super.from,
    required super.to,
    required super.minutes,
    required super.baseRate,
    super.appliedRuleId,
    required super.ruleType,
    required super.rate,
    required super.amount,
  });

  factory PricingSegmentModel.fromJson(Map<String, dynamic> json) {
    return PricingSegmentModel(
      from: (json['from'] ?? '00:00:00').toString(),
      to: (json['to'] ?? '00:00:00').toString(),
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      baseRate: (json['base_rate'] as num?)?.toDouble() ?? 0.0,
      appliedRuleId: json['applied_rule_id']?.toString(),
      ruleType: (json['rule_type'] ?? 'standard').toString(),
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PricingQuoteModel extends PricingQuoteEntity {
  const PricingQuoteModel({
    required super.segments,
    required super.roomSubtotal,
    required super.extraControllersAmount,
    required super.discountAmount,
    required super.total,
    super.currency = 'EGP',
    super.hasPeak = false,
    super.pricingVersion = 1,
  });

  factory PricingQuoteModel.fromJson(Map<String, dynamic> json) {
    List<PricingSegmentModel> parsedSegments = [];
    if (json['segments'] is List) {
      parsedSegments = (json['segments'] as List)
          .map((e) => PricingSegmentModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return PricingQuoteModel(
      segments: parsedSegments,
      roomSubtotal: (json['room_subtotal'] as num?)?.toDouble() ?? 0.0,
      extraControllersAmount:
          (json['extra_controllers_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] ?? 'EGP').toString(),
      hasPeak: json['has_peak'] as bool? ?? false,
      pricingVersion: (json['pricing_version'] as num?)?.toInt() ?? 1,
    );
  }
}
