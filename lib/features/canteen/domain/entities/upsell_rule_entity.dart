import 'package:equatable/equatable.dart';

class UpsellRuleEntity extends Equatable {
  final String id;
  final String loungeId;
  final String triggerType;
  final Map<String, dynamic> triggerParams;
  final String? suggestExtraId;
  final String? suggestComboId;
  final double? discountPercent;
  final int maxImpressionsPerBooking;
  final int priority;
  final bool isActive;
  final DateTime? createdAt;
  final String? suggestedNameAr;
  final String? suggestedNameEn;
  final double? suggestedPrice;
  final String? suggestedImageUrl;
  final bool isCombo;

  const UpsellRuleEntity({
    required this.id,
    required this.loungeId,
    required this.triggerType,
    this.triggerParams = const {},
    this.suggestExtraId,
    this.suggestComboId,
    this.discountPercent,
    this.maxImpressionsPerBooking = 2,
    this.priority = 100,
    this.isActive = true,
    this.createdAt,
    this.suggestedNameAr,
    this.suggestedNameEn,
    this.suggestedPrice,
    this.suggestedImageUrl,
    this.isCombo = false,
  });

  @override
  List<Object?> get props => [
        id,
        loungeId,
        triggerType,
        triggerParams,
        suggestExtraId,
        suggestComboId,
        discountPercent,
        maxImpressionsPerBooking,
        priority,
        isActive,
        createdAt,
        suggestedNameAr,
        suggestedNameEn,
        suggestedPrice,
        suggestedImageUrl,
        isCombo,
      ];
}
