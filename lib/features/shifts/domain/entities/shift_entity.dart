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
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? managerNotes;

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
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
    this.managerNotes,
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
        isApproved,
        approvedBy,
        approvedAt,
        managerNotes,
      ];
}
