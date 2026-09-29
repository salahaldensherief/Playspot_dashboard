import 'package:equatable/equatable.dart';

enum PricingRuleStatus {
  active,
  scheduled,
  expired;

  String get value {
    switch (this) {
      case PricingRuleStatus.active:
        return 'active';
      case PricingRuleStatus.scheduled:
        return 'scheduled';
      case PricingRuleStatus.expired:
        return 'expired';
    }
  }
}

class PricingRuleEntity extends Equatable {
  final String id;
  final String loungeId;
  final String? spaceTypeId;
  final String? roomId;
  final String nameAr;
  final String nameEn;
  final String ruleType; // 'peak', 'off_peak', 'standard', 'custom'
  final List<int> daysOfWeek; // 1 = Mon, 7 = Sun
  final String startTime; // '16:00:00'
  final String endTime; // '22:00:00'
  final DateTime? startDate;
  final DateTime? endDate;
  final String adjustmentType; // 'multiplier', 'percentage', 'fixed'
  final double adjustmentValue;
  final bool isActive;
  final int priority;
  final DateTime createdAt;

  const PricingRuleEntity({
    required this.id,
    required this.loungeId,
    this.spaceTypeId,
    this.roomId,
    required this.nameAr,
    required this.nameEn,
    this.ruleType = 'peak',
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    required this.startTime,
    required this.endTime,
    this.startDate,
    this.endDate,
    this.adjustmentType = 'multiplier',
    this.adjustmentValue = 1.0,
    this.isActive = true,
    this.priority = 10,
    required this.createdAt,
  });

  bool get isOvernight {
    if (startTime.isEmpty || endTime.isEmpty) return false;
    return endTime.compareTo(startTime) <= 0;
  }

  PricingRuleStatus get status {
    if (!isActive) return PricingRuleStatus.expired;
    final now = DateTime.now();
    if (startDate != null && startDate!.isAfter(now)) {
      return PricingRuleStatus.scheduled;
    }
    if (endDate != null && endDate!.isBefore(now)) {
      return PricingRuleStatus.expired;
    }
    return PricingRuleStatus.active;
  }

  @override
  List<Object?> get props => [
        id,
        loungeId,
        spaceTypeId,
        roomId,
        nameAr,
        nameEn,
        ruleType,
        daysOfWeek,
        startTime,
        endTime,
        startDate,
        endDate,
        adjustmentType,
        adjustmentValue,
        isActive,
        priority,
        createdAt,
      ];
}
