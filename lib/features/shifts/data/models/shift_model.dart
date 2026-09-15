import '../../domain/entities/shift_entity.dart';

class ShiftModel extends ShiftEntity {
  const ShiftModel({
    required super.id,
    super.loungeId,
    required super.cashierId,
    super.cashierName,
    required super.startingCash,
    super.cashRevenue,
    super.digitalRevenue,
    super.expensesTotal,
    super.cashDropsTotal,
    super.expectedCash,
    super.actualCash,
    super.discrepancy,
    required super.status,
    required super.startTime,
    super.endTime,
    super.notes,
    super.isApproved,
    super.approvedBy,
    super.approvedAt,
    super.managerNotes,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr.toString());
      } catch (_) {
        return null;
      }
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final starting = parseDouble(json['starting_cash'] ?? json['opening_cash']);
    final cashRev = parseDouble(json['total_cash_sales'] ?? json['cash_revenue']);
    final digRev = parseDouble(json['total_digital_sales'] ?? json['digital_revenue']);
    final expTotal = parseDouble(json['total_expenses'] ?? json['expenses_total']);
    final dropsTotal = parseDouble(json['total_cash_drops'] ?? json['cash_drops_total']);
    
    // Unified Expected Cash formula
    final rawExpected = json['expected_cash'];
    final computedExpected = rawExpected != null 
        ? parseDouble(rawExpected) 
        : (starting + cashRev - expTotal - dropsTotal);

    final actual = json['actual_cash_counted'] != null || json['actual_cash'] != null
        ? parseDouble(json['actual_cash_counted'] ?? json['actual_cash'])
        : null;

    final rawDiff = json['difference'] ?? json['discrepancy'];
    final computedDiff = rawDiff != null 
        ? parseDouble(rawDiff) 
        : (actual != null ? (actual - computedExpected) : 0.0);

    return ShiftModel(
      id: (json['id'] ?? json['shift_id'] ?? '').toString(),
      loungeId: json['lounge_id']?.toString() ?? json['loungeId']?.toString(),
      cashierId: (json['cashier_id'] ?? json['staff_id'] ?? json['staff_user_id'] ?? '').toString(),
      cashierName: json['profiles']?['full_name']?.toString() ?? json['cashier_name']?.toString() ?? 'N/A',
      startingCash: starting,
      cashRevenue: cashRev,
      digitalRevenue: digRev,
      expensesTotal: expTotal,
      cashDropsTotal: dropsTotal,
      expectedCash: computedExpected,
      actualCash: actual,
      discrepancy: computedDiff,
      status: (json['status'] ?? 'open').toString(),
      startTime: parseDate(json['created_at'] ?? json['start_time'] ?? json['opened_at']) ?? DateTime.now(),
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
      if (loungeId != null) 'lounge_id': loungeId,
      'staff_id': cashierId,
      'cashier_id': cashierId,
      'starting_cash': startingCash,
      'actual_cash_counted': actualCash,
      'difference': discrepancy,
      'status': status,
      'created_at': startTime.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (endTime != null) 'end_time': endTime?.toIso8601String(),
      'is_approved': isApproved,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (approvedAt != null) 'approved_at': approvedAt?.toIso8601String(),
      if (managerNotes != null) 'manager_notes': managerNotes,
    };
  }
}
