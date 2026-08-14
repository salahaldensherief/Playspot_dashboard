import '../entities/shift_entity.dart';

class ShiftModel extends ShiftEntity {
  const ShiftModel({
    required super.id,
    required super.cashierId,
    super.cashierName,
    required super.startTime,
    super.endTime,
    required super.startingCash,
    super.actualCash,
    super.expectedCash,
    super.cashRevenue,
    super.digitalRevenue,
    super.totalRevenue,
    required super.status,
    super.notes,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id']?.toString() ?? '',
      cashierId: json['cashier_id']?.toString() ?? '',
      cashierName: json['cashier_name']?.toString() ?? json['profiles']?['full_name'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      startingCash: (json['starting_cash'] as num?)?.toDouble() ?? 0.0,
      actualCash: (json['actual_cash'] as num?)?.toDouble(),
      expectedCash: (json['expected_cash'] as num?)?.toDouble(),
      cashRevenue: (json['cash_revenue'] as num?)?.toDouble(),
      digitalRevenue: (json['digital_revenue'] as num?)?.toDouble(),
      totalRevenue: (json['total_revenue'] as num?)?.toDouble(),
      status: json['status'] ?? 'open',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cashier_id': cashierId,
      'starting_cash': startingCash,
      'status': status,
      'notes': notes,
      'start_time': startTime.toIso8601String(),
      if (actualCash != null) 'actual_cash': actualCash,
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
    };
  }
}
