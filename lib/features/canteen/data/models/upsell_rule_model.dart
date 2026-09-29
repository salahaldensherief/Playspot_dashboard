import '../../domain/entities/upsell_rule_entity.dart';

class UpsellRuleModel extends UpsellRuleEntity {
  const UpsellRuleModel({
    required super.id,
    required super.loungeId,
    required super.triggerType,
    super.triggerParams = const {},
    super.suggestExtraId,
    super.suggestComboId,
    super.discountPercent,
    super.maxImpressionsPerBooking = 2,
    super.priority = 100,
    super.isActive = true,
    super.createdAt,
    super.suggestedNameAr,
    super.suggestedNameEn,
    super.suggestedPrice,
    super.suggestedImageUrl,
    super.isCombo = false,
  });

  factory UpsellRuleModel.fromJson(Map<String, dynamic> json) {
    final rawParams = json['trigger_params'];
    Map<String, dynamic> params = {};
    if (rawParams is Map) {
      params = Map<String, dynamic>.from(rawParams);
    }

    final extra = json['extras'];
    final combo = json['canteen_combos'];

    String? nameAr;
    String? nameEn;
    double? price;
    String? imageUrl;
    bool isCombo = false;

    if (combo is Map) {
      isCombo = true;
      nameAr = combo['name_ar']?.toString();
      nameEn = combo['name_en']?.toString();
      price = (combo['price'] as num?)?.toDouble();
      imageUrl = combo['image_url']?.toString();
    } else if (extra is Map) {
      isCombo = false;
      nameAr = extra['name_ar']?.toString();
      nameEn = extra['name_en']?.toString();
      price = (extra['price'] as num?)?.toDouble();
      imageUrl = extra['image_url']?.toString();
    }

    final rawCreatedAt = json['created_at'];

    return UpsellRuleModel(
      id: (json['id'] ?? '').toString(),
      loungeId: (json['lounge_id'] ?? '').toString(),
      triggerType: (json['trigger_type'] ?? 'session_minutes_elapsed').toString(),
      triggerParams: params,
      suggestExtraId: json['suggest_extra_id']?.toString(),
      suggestComboId: json['suggest_combo_id']?.toString(),
      discountPercent: (json['discount_percent'] as num?)?.toDouble(),
      maxImpressionsPerBooking: (json['max_impressions_per_booking'] as num?)?.toInt() ?? 2,
      priority: (json['priority'] as num?)?.toInt() ?? 100,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt.toString()) : null,
      suggestedNameAr: nameAr,
      suggestedNameEn: nameEn,
      suggestedPrice: price,
      suggestedImageUrl: imageUrl,
      isCombo: isCombo || json['suggest_combo_id'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.isNotEmpty ? id : null,
      'lounge_id': loungeId,
      'trigger_type': triggerType,
      'trigger_params': triggerParams,
      'suggest_extra_id': suggestExtraId,
      'suggest_combo_id': suggestComboId,
      'discount_percent': discountPercent,
      'max_impressions_per_booking': maxImpressionsPerBooking,
      'priority': priority,
      'is_active': isActive,
    }..removeWhere((key, value) => value == null && key == 'id');
  }
}
