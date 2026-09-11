import 'package:equatable/equatable.dart';

class LoyaltyStatsModel extends Equatable {
  final int totalAddedPoints;
  final Map<String, int> userCountByLevel;
  final int totalReferrals;
  final int completedReferrals;
  final int totalReferralPoints;
  final int totalVouchersIssued;
  final int totalVouchersUsed;
  final int totalVouchersActive;
  final double totalDiscountValueUsed;

  const LoyaltyStatsModel({
    required this.totalAddedPoints,
    required this.userCountByLevel,
    required this.totalReferrals,
    required this.completedReferrals,
    required this.totalReferralPoints,
    this.totalVouchersIssued = 0,
    this.totalVouchersUsed = 0,
    this.totalVouchersActive = 0,
    this.totalDiscountValueUsed = 0.0,
  });

  factory LoyaltyStatsModel.fromJson(Map<String, dynamic> json) {
    final rawLevelMap = json['user_count_by_level'] as Map<String, dynamic>? ?? {};
    final levelMap = rawLevelMap.map((k, v) => MapEntry(k, (v as num).toInt()));

    return LoyaltyStatsModel(
      totalAddedPoints: (json['total_added_points'] as num?)?.toInt() ?? 0,
      userCountByLevel: levelMap,
      totalReferrals: (json['total_referrals'] as num?)?.toInt() ?? 0,
      completedReferrals: (json['completed_referrals'] as num?)?.toInt() ?? 0,
      totalReferralPoints: (json['total_referral_points'] as num?)?.toInt() ?? 0,
      totalVouchersIssued: (json['total_vouchers_issued'] as num?)?.toInt() ?? 0,
      totalVouchersUsed: (json['total_vouchers_used'] as num?)?.toInt() ?? 0,
      totalVouchersActive: (json['total_vouchers_active'] as num?)?.toInt() ?? 0,
      totalDiscountValueUsed: (json['total_discount_value_used'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_added_points': totalAddedPoints,
      'user_count_by_level': userCountByLevel,
      'total_referrals': totalReferrals,
      'completed_referrals': completedReferrals,
      'total_referral_points': totalReferralPoints,
      'total_vouchers_issued': totalVouchersIssued,
      'total_vouchers_used': totalVouchersUsed,
      'total_vouchers_active': totalVouchersActive,
      'total_discount_value_used': totalDiscountValueUsed,
    };
  }

  @override
  List<Object?> get props => [
        totalAddedPoints,
        userCountByLevel,
        totalReferrals,
        completedReferrals,
        totalReferralPoints,
        totalVouchersIssued,
        totalVouchersUsed,
        totalVouchersActive,
        totalDiscountValueUsed,
      ];
}
