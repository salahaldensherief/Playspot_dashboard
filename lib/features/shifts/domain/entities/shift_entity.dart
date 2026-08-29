import 'package:equatable/equatable.dart';

class ShiftEntity extends Equatable {
  final String id;
  final String cashierId;
  final String? cashierName;
  final double startingCash;
  final double? cashRevenue;
  final double? digitalRevenue;
  final double? expectedCash;
  final double? actualCash;
  final double? discrepancy;
  final String status; // 'open' or 'closed'
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;

  double get totalRevenue => (cashRevenue ?? 0) + (digitalRevenue ?? 0);

  const ShiftEntity({
    required this.id,
    required this.cashierId,
    this.cashierName,
    required this.startingCash,
    this.cashRevenue,
    this.digitalRevenue,
    this.expectedCash,
    this.actualCash,
    this.discrepancy,
    required this.status,
    required this.startTime,
    this.endTime,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        cashierId,
        cashierName,
        startingCash,
        cashRevenue,
        digitalRevenue,
        expectedCash,
        actualCash,
        discrepancy,
        status,
        startTime,
        endTime,
        notes,
      ];
}
