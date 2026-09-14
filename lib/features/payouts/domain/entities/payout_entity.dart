import 'package:equatable/equatable.dart';

class PayoutEntity extends Equatable {
  final String id;
  final String loungeId;
  final String? loungeName;
  final double amount;
  final String periodStart;
  final String periodEnd;
  final String status; // pending, approved, processing, paid, failed, cancelled, reversed, needs_review
  final String? notes;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? transferReference;
  final String? transferMethod;
  final int? paymentCount;

  const PayoutEntity({
    required this.id,
    required this.loungeId,
    this.loungeName,
    required this.amount,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    this.notes,
    required this.createdAt,
    this.paidAt,
    this.transferReference,
    this.transferMethod,
    this.paymentCount,
  });

  @override
  List<Object?> get props => [
        id,
        loungeId,
        loungeName,
        amount,
        periodStart,
        periodEnd,
        status,
        notes,
        createdAt,
        paidAt,
        transferReference,
        transferMethod,
        paymentCount,
      ];
}

class PendingPayoutOverview extends Equatable {
  final String loungeId;
  final String loungeName;
  final double pendingAmount;
  final int pendingPaymentsCount;

  const PendingPayoutOverview({
    required this.loungeId,
    required this.loungeName,
    required this.pendingAmount,
    required this.pendingPaymentsCount,
  });

  @override
  List<Object?> get props => [loungeId, loungeName, pendingAmount, pendingPaymentsCount];
}
