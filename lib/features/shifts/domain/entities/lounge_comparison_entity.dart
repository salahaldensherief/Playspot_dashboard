import 'package:equatable/equatable.dart';

class LoungeComparisonEntity extends Equatable {
  final String loungeId;
  final String loungeName;
  final int shiftCount;
  final int openShiftCount;
  final double totalSales;
  final double totalExpenses;
  final double totalDifference;
  final double averageShiftSales;
  final int pendingApprovalCount;

  const LoungeComparisonEntity({
    required this.loungeId,
    required this.loungeName,
    required this.shiftCount,
    required this.openShiftCount,
    required this.totalSales,
    required this.totalExpenses,
    required this.totalDifference,
    required this.averageShiftSales,
    required this.pendingApprovalCount,
  });

  @override
  List<Object?> get props => [
        loungeId,
        loungeName,
        shiftCount,
        openShiftCount,
        totalSales,
        totalExpenses,
        totalDifference,
        averageShiftSales,
        pendingApprovalCount,
      ];
}
