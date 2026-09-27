import 'package:equatable/equatable.dart';

class ShiftPaymentEntity extends Equatable {
  final String id;
  final String shiftId;
  final double amount;
  final String paymentMethod;
  final String category;
  final String? bookingId;
  final DateTime createdAt;

  const ShiftPaymentEntity({
    required this.id,
    required this.shiftId,
    required this.amount,
    required this.paymentMethod,
    required this.category,
    this.bookingId,
    required this.createdAt,
  });

  bool get isCash => paymentMethod.toLowerCase() == 'cash';
  bool get isDigital => !isCash;

  @override
  List<Object?> get props => [
        id,
        shiftId,
        amount,
        paymentMethod,
        category,
        bookingId,
        createdAt,
      ];
}
