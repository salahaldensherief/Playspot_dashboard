class LoyaltyStatsModel {
  final int totalVouchersIssued;
  final int totalVouchersUsed;
  final int totalVouchersActive;
  final double totalDiscountValueUsed;

  LoyaltyStatsModel({
    required this.totalVouchersIssued,
    required this.totalVouchersUsed,
    required this.totalVouchersActive,
    required this.totalDiscountValueUsed,
  });

  factory LoyaltyStatsModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyStatsModel(
      totalVouchersIssued: (json['total_vouchers_issued'] as num?)?.toInt() ?? 0,
      totalVouchersUsed: (json['total_vouchers_used'] as num?)?.toInt() ?? 0,
      totalVouchersActive: (json['total_vouchers_active'] as num?)?.toInt() ?? 0,
      totalDiscountValueUsed: (json['total_discount_value_used'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
