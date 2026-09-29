import '../../domain/entities/pricing_rule_entity.dart';

class PricingRuleModel extends PricingRuleEntity {
  const PricingRuleModel({
    required super.id,
    required super.loungeId,
    super.spaceTypeId,
    super.roomId,
    required super.nameAr,
    required super.nameEn,
    super.ruleType = 'peak',
    super.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    required super.startTime,
    required super.endTime,
    super.startDate,
    super.endDate,
    super.adjustmentType = 'multiplier',
    super.adjustmentValue = 1.0,
    super.isActive = true,
    super.priority = 10,
    required super.createdAt,
  });

  factory PricingRuleModel.fromJson(Map<String, dynamic> json) {
    List<int> parsedDays = [];
    if (json['days_of_week'] is List) {
      parsedDays = (json['days_of_week'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 1)
          .toList();
    } else if (json['days'] is List) {
      parsedDays = (json['days'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 1)
          .toList();
    }
    if (parsedDays.isEmpty) {
      parsedDays = [1, 2, 3, 4, 5, 6, 7];
    }

    final rawStartDate = json['start_date'];
    final rawEndDate = json['end_date'];
    final rawCreatedAt = json['created_at'];

    return PricingRuleModel(
      id: (json['id'] ?? '').toString(),
      loungeId: (json['lounge_id'] ?? '').toString(),
      spaceTypeId: json['space_type_id']?.toString(),
      roomId: json['room_id']?.toString(),
      nameAr: (json['name_ar'] ?? json['name'] ?? 'قاعدة تسعير').toString(),
      nameEn: (json['name_en'] ?? json['name'] ?? 'Pricing Rule').toString(),
      ruleType: (json['rule_type'] ?? 'peak').toString(),
      daysOfWeek: parsedDays,
      startTime: (json['start_time'] ?? '00:00:00').toString(),
      endTime: (json['end_time'] ?? '23:59:59').toString(),
      startDate: rawStartDate != null
          ? DateTime.tryParse(rawStartDate.toString())
          : null,
      endDate: rawEndDate != null ? DateTime.tryParse(rawEndDate.toString()) : null,
      adjustmentType: (json['adjustment_type'] ?? 'multiplier').toString(),
      adjustmentValue: (json['adjustment_value'] as num?)?.toDouble() ??
          (json['multiplier'] as num?)?.toDouble() ??
          1.0,
      isActive: json['is_active'] as bool? ?? true,
      priority: (json['priority'] as num?)?.toInt() ?? 10,
      createdAt: rawCreatedAt != null
          ? DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'lounge_id': loungeId,
      'space_type_id': spaceTypeId,
      'room_id': roomId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'rule_type': ruleType,
      'days_of_week': daysOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'adjustment_type': adjustmentType,
      'adjustment_value': adjustmentValue,
      'is_active': isActive,
      'priority': priority,
    };
  }
}
