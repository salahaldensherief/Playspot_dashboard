import '../../domain/entities/cashier_performance_entity.dart';

class CashierPerformanceModel extends CashierPerformanceEntity {
  const CashierPerformanceModel({
    required super.cashierId,
    required super.cashierName,
    required super.shiftCount,
    required super.closedShiftCount,
    required super.approvedShiftCount,
    required super.totalSales,
    required super.cashSales,
    required super.digitalSales,
    required super.totalExpenses,
    required super.totalDifference,
    required super.averageShiftSales,
    required super.openShiftCount,
  });

  factory CashierPerformanceModel.fromJson(Map<String, dynamic> json) {
    return CashierPerformanceModel(
      cashierId: (json['cashier_id'] ?? '').toString(),
      cashierName: (json['cashier_name'] ?? 'N/A').toString(),
      shiftCount: (json['shift_count'] ?? 0) as int,
      closedShiftCount: (json['closed_shift_count'] ?? 0) as int,
      approvedShiftCount: (json['approved_shift_count'] ?? 0) as int,
      totalSales: ((json['total_sales'] ?? 0) as num).toDouble(),
      cashSales: ((json['cash_sales'] ?? 0) as num).toDouble(),
      digitalSales: ((json['digital_sales'] ?? 0) as num).toDouble(),
      totalExpenses: ((json['total_expenses'] ?? 0) as num).toDouble(),
      totalDifference: ((json['total_difference'] ?? 0) as num).toDouble(),
      averageShiftSales: ((json['average_shift_sales'] ?? 0) as num).toDouble(),
      openShiftCount: (json['open_shift_count'] ?? 0) as int,
    );
  }
}
