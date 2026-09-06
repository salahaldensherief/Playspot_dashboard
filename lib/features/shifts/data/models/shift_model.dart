import '../../domain/entities/shift_entity.dart';

class ShiftModel extends ShiftEntity {
  const ShiftModel({
    required super.id,
    required super.cashierId,
    super.cashierName,
    required super.startingCash,
    super.cashRevenue,
    super.digitalRevenue,
    super.expectedCash,
    super.actualCash,
    super.discrepancy,
    required super.status,
    required    super.startTime,
    super.endTime,
    super.notes,
    super.isApproved,
    super.approvedBy,
    super.approvedAt,
    super.managerNotes,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    // Safe parsing for DateTime with fallbacks
    DateTime? parseDate(dynamic dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr.toString());
      } catch (_) {
        return null;
      }
    }

    return ShiftModel(
      id: (json['id'] ?? json['shift_id'] ?? '').toString(),
      cashierId: (json['cashier_id'] ?? json['staff_user_id'] ?? '').toString(),
      cashierName: json['profiles']?['full_name']?.toString() ?? json['cashier_name']?.toString() ?? 'N/A',
      startingCash: (json['starting_cash'] ?? json['opening_cash'] ?? 0).toDouble(),
      cashRevenue: (json['total_cash_sales'] ?? json['cash_revenue'] ?? 0).toDouble(),
      digitalRevenue: (json['total_digital_sales'] ?? json['digital_revenue'] ?? 0).toDouble(),
      expectedCash: (json['expected_cash'] ?? 0).toDouble(),
      actualCash: (json['actual_cash_counted'] ?? json['actual_cash'] ?? 0).toDouble(),
      discrepancy: (json['difference'] ?? json['discrepancy'] ?? 0).toDouble(),
      status: (json['status'] ?? 'open').toString(),
      startTime: parseDate(json['start_time'] ?? json['opened_at']) ?? DateTime.now(),
      endTime: parseDate(json['end_time'] ?? json['closed_at']),
      notes: json['notes']?.toString(),
      isApproved: json['is_approved'] ?? false,
      approvedBy: json['approved_by']?.toString(),
      approvedAt: parseDate(json['approved_at']),
      managerNotes: json['manager_notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cashier_id': cashierId,
      'starting_cash': startingCash,
      'actual_cash_counted': actualCash,
      'difference': discrepancy,
      'notes': notes,
      'status': status,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_approved': isApproved,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'manager_notes': managerNotes,
    };
  }
}
