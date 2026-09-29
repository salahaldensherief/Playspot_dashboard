import 'package:equatable/equatable.dart';

class PricingSegmentEntity extends Equatable {
  final String from;
  final String to;
  final int minutes;
  final double baseRate;
  final String? appliedRuleId;
  final String ruleType;
  final double rate;
  final double amount;

  const PricingSegmentEntity({
    required this.from,
    required this.to,
    required this.minutes,
    required this.baseRate,
    this.appliedRuleId,
    required this.ruleType,
    required this.rate,
    required this.amount,
  });

  @override
  List<Object?> get props => [
        from,
        to,
        minutes,
        baseRate,
        appliedRuleId,
        ruleType,
        rate,
        amount,
      ];
}

class PricingQuoteEntity extends Equatable {
  final List<PricingSegmentEntity> segments;
  final double roomSubtotal;
  final double extraControllersAmount;
  final double discountAmount;
  final double total;
  final String currency;
  final bool hasPeak;
  final int pricingVersion;

  const PricingQuoteEntity({
    required this.segments,
    required this.roomSubtotal,
    required this.extraControllersAmount,
    required this.discountAmount,
    required this.total,
    this.currency = 'EGP',
    this.hasPeak = false,
    this.pricingVersion = 1,
  });

  @override
  List<Object?> get props => [
        segments,
        roomSubtotal,
        extraControllersAmount,
        discountAmount,
        total,
        currency,
        hasPeak,
        pricingVersion,
      ];
}
