import '../../domain/entities/shift_payment_entity.dart';

class ShiftPaymentModel extends ShiftPaymentEntity {
  const ShiftPaymentModel({
    required super.id,
    required super.shiftId,
    required super.amount,
    required super.paymentMethod,
    required super.category,
    super.bookingId,
    required super.createdAt,
  });

  factory ShiftPaymentModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return ShiftPaymentModel(
      id: (json['id'] ?? '').toString(),
      shiftId: (json['shift_id'] ?? '').toString(),
      amount: parseDouble(json['amount'] ?? json['total_amount']),
      paymentMethod: (json['payment_method'] ?? json['method'] ?? 'cash').toString(),
      category: (json['category'] ?? json['type'] ?? 'play_time').toString(),
      bookingId: json['booking_id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'shift_id': shiftId,
      'amount': amount,
      'payment_method': paymentMethod,
      'category': category,
      if (bookingId != null) 'booking_id': bookingId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
