import 'package:equatable/equatable.dart';

class UpsellConversionEntity extends Equatable {
  final String loungeId;
  final String? ruleId;
  final String? triggerType;
  final int impressions;
  final int conversions;
  final double conversionRatePercent;
  final double revenueGenerated;

  const UpsellConversionEntity({
    required this.loungeId,
    this.ruleId,
    this.triggerType,
    required this.impressions,
    required this.conversions,
    required this.conversionRatePercent,
    required this.revenueGenerated,
  });

  @override
  List<Object?> get props => [
        loungeId,
        ruleId,
        triggerType,
        impressions,
        conversions,
        conversionRatePercent,
        revenueGenerated,
      ];
}
