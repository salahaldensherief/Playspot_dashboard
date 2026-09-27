import 'package:equatable/equatable.dart';

class CashierPerformanceEntity extends Equatable {
  final String cashierId;
  final String cashierName;
  final int shiftCount;
  final int closedShiftCount;
  final int approvedShiftCount;
  final double totalSales;
  final double cashSales;
  final double digitalSales;
  final double totalExpenses;
  final double totalDifference;
  final double averageShiftSales;
  final int openShiftCount;

  const CashierPerformanceEntity({
    required this.cashierId,
    required this.cashierName,
    required this.shiftCount,
    required this.closedShiftCount,
    required this.approvedShiftCount,
    required this.totalSales,
    required this.cashSales,
    required this.digitalSales,
    required this.totalExpenses,
    required this.totalDifference,
    required this.averageShiftSales,
    required this.openShiftCount,
  });

  @override
  List<Object?> get props => [
        cashierId,
        cashierName,
        shiftCount,
        closedShiftCount,
        approvedShiftCount,
        totalSales,
        cashSales,
        digitalSales,
        totalExpenses,
        totalDifference,
        averageShiftSales,
        openShiftCount,
      ];
}
