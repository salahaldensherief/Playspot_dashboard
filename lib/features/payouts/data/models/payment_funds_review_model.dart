import '../../domain/entities/payment_funds_review.dart';

class PaymentFundsReviewModel extends PaymentFundsReview {
  const PaymentFundsReviewModel({
    required super.id,
    required super.loungeId,
    super.loungeName,
    required super.bookingId,
    required super.paymentMethod,
    required super.amount,
    required super.paidAt,
  });

  factory PaymentFundsReviewModel.fromJson(Map<String, dynamic> json) {
    final amount = double.tryParse(json['amount'].toString());
    final paidAt = DateTime.tryParse(json['paid_at'].toString());
    final id = json['id'];
    final loungeId = json['lounge_id'];
    final method = json['payment_method'];
    if (amount == null ||
        !amount.isFinite ||
        amount < 0 ||
        paidAt == null ||
        id is! String ||
        id.isEmpty ||
        loungeId is! String ||
        loungeId.isEmpty ||
        method is! String ||
        method.isEmpty) {
      throw const FormatException('Invalid payment custody review response');
    }
    return PaymentFundsReviewModel(
      id: id,
      loungeId: loungeId,
      loungeName: json['lounge_name'] as String?,
      bookingId: json['booking_id'] as String?,
      paymentMethod: method,
      amount: amount,
      paidAt: paidAt,
    );
  }
}
