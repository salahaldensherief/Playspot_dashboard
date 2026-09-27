import 'package:equatable/equatable.dart';

class ShiftExpenseEntity extends Equatable {
  final String id;
  final String shiftId;
  final String loungeId;
  final double amount;
  final String type; // 'expense' or 'cash_drop'
  final String reason;
  final String? createdBy;
  final String? createdByName;
  final DateTime createdAt;

  const ShiftExpenseEntity({
    required this.id,
    required this.shiftId,
    required this.loungeId,
    required this.amount,
    required this.type,
    required this.reason,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
  });

  bool get isCashDrop => type == 'cash_drop';

  @override
  List<Object?> get props => [
        id,
        shiftId,
        loungeId,
        amount,
        type,
        reason,
        createdBy,
        createdByName,
        createdAt,
      ];
}
