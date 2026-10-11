import 'package:equatable/equatable.dart';

enum PaymentFundsHolder { platform, lounge }

class PaymentFundsReview extends Equatable {
  final String id;
  final String loungeId;
  final String? loungeName;
  final String? bookingId;
  final String paymentMethod;
  final double amount;
  final DateTime paidAt;

  const PaymentFundsReview({
    required this.id,
    required this.loungeId,
    this.loungeName,
    required this.bookingId,
    required this.paymentMethod,
    required this.amount,
    required this.paidAt,
  });

  @override
  List<Object?> get props => [
    id,
    loungeId,
    loungeName,
    bookingId,
    paymentMethod,
    amount,
    paidAt,
  ];
}
