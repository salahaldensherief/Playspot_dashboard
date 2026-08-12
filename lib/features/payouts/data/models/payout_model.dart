import '../../domain/entities/payout_entity.dart';

class PayoutModel extends PayoutEntity {
  const PayoutModel({
    required super.id,
    required super.loungeId,
    super.loungeName,
    required super.amount,
    required super.periodStart,
    required super.periodEnd,
    required super.status,
    super.notes,
    required super.createdAt,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['id'] as String,
      loungeId: json['lounge_id'] as String,
      loungeName: json['lounge_name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      periodStart: json['period_start'] as String,
      periodEnd: json['period_end'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class PendingPayoutOverviewModel extends PendingPayoutOverview {
  const PendingPayoutOverviewModel({
    required super.loungeId,
    required super.loungeName,
    required super.pendingAmount,
    required super.pendingPaymentsCount,
  });

  factory PendingPayoutOverviewModel.fromJson(Map<String, dynamic> json) {
    return PendingPayoutOverviewModel(
      loungeId: json['lounge_id'] as String,
      loungeName: json['lounge_name'] as String,
      pendingAmount: (json['pending_amount'] as num).toDouble(),
      pendingPaymentsCount: (json['pending_payments_count'] as num).toInt(),
    );
  }
}
