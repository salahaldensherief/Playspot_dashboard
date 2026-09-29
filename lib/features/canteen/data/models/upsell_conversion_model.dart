import '../../domain/entities/upsell_conversion_entity.dart';

class UpsellConversionModel extends UpsellConversionEntity {
  const UpsellConversionModel({
    required super.loungeId,
    super.ruleId,
    super.triggerType,
    required super.impressions,
    required super.conversions,
    required super.conversionRatePercent,
    required super.revenueGenerated,
  });

  factory UpsellConversionModel.fromJson(Map<String, dynamic> json) {
    return UpsellConversionModel(
      loungeId: (json['lounge_id'] ?? '').toString(),
      ruleId: json['rule_id']?.toString(),
      triggerType: json['trigger_type']?.toString(),
      impressions: (json['impressions'] as num?)?.toInt() ?? 0,
      conversions: (json['conversions'] as num?)?.toInt() ?? 0,
      conversionRatePercent: (json['conversion_rate_percent'] as num?)?.toDouble() ?? 0.0,
      revenueGenerated: (json['revenue_generated'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
