import '../../domain/entities/shift_expense_entity.dart';

class ShiftExpenseModel extends ShiftExpenseEntity {
  const ShiftExpenseModel({
    required super.id,
    required super.shiftId,
    required super.loungeId,
    required super.amount,
    required super.type,
    required super.reason,
    super.createdBy,
    super.createdByName,
    required super.createdAt,
  });

  factory ShiftExpenseModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    final profileData = json['profiles'] as Map<String, dynamic>?;

    return ShiftExpenseModel(
      id: (json['id'] ?? '').toString(),
      shiftId: (json['shift_id'] ?? '').toString(),
      loungeId: (json['lounge_id'] ?? '').toString(),
      amount: parseDouble(json['amount']),
      type: (json['type'] ?? 'expense').toString().toLowerCase(),
      reason: (json['reason'] ?? json['notes'] ?? '').toString(),
      createdBy: json['created_by']?.toString(),
      createdByName: (json['created_by_name'] ?? profileData?['full_name'])?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shift_id': shiftId,
      'lounge_id': loungeId,
      'amount': amount,
      'type': type,
      'reason': reason,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}
