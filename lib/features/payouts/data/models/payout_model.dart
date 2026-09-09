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
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return PayoutModel(
      id: (json['id'] ?? '').toString(),
      loungeId: (json['lounge_id'] ?? '').toString(),
      loungeName: json['lounge_name']?.toString(),
      amount: parseDouble(json['total_amount'] ?? json['amount']),
      periodStart: (json['period_start'] ?? '').toString(),
      periodEnd: (json['period_end'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
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
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return PendingPayoutOverviewModel(
      loungeId: (json['lounge_id'] ?? '').toString(),
      loungeName: (json['lounge_name'] ?? 'Lounge').toString(),
      pendingAmount: parseDouble(json['pending_amount'] ?? json['total_amount'] ?? json['amount']),
      pendingPaymentsCount: parseInt(json['pending_payments_count'] ?? json['count']),
    );
  }
}
