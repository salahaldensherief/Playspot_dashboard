import '../../domain/entities/lounge_comparison_entity.dart';

class LoungeComparisonModel extends LoungeComparisonEntity {
  const LoungeComparisonModel({
    required super.loungeId,
    required super.loungeName,
    required super.shiftCount,
    required super.openShiftCount,
    required super.totalSales,
    required super.totalExpenses,
    required super.totalDifference,
    required super.averageShiftSales,
    required super.pendingApprovalCount,
  });

  factory LoungeComparisonModel.fromJson(Map<String, dynamic> json) {
    return LoungeComparisonModel(
      loungeId: (json['lounge_id'] ?? '').toString(),
      loungeName: (json['lounge_name'] ?? 'N/A').toString(),
      shiftCount: (json['shift_count'] ?? 0) as int,
      openShiftCount: (json['open_shift_count'] ?? 0) as int,
      totalSales: ((json['total_sales'] ?? 0) as num).toDouble(),
      totalExpenses: ((json['total_expenses'] ?? 0) as num).toDouble(),
      totalDifference: ((json['total_difference'] ?? 0) as num).toDouble(),
      averageShiftSales: ((json['average_shift_sales'] ?? 0) as num).toDouble(),
      pendingApprovalCount: (json['pending_approval_count'] ?? 0) as int,
    );
  }
}
