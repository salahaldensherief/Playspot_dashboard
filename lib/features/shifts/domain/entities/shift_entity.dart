import 'package:equatable/equatable.dart';

class ShiftEntity extends Equatable {
  final String id;
  final String cashierId;
  final String? cashierName;
  final DateTime startTime;
  final DateTime? endTime;
  final double startingCash;
  final double? actualCash;
  final double? expectedCash;
  final double? cashRevenue;
  final double? digitalRevenue;
  final double? totalRevenue;
  final String status; // 'open', 'closed'
  final String? notes;

  const ShiftEntity({
    required this.id,
    required this.cashierId,
    this.cashierName,
    required this.startTime,
    this.endTime,
    required this.startingCash,
    this.actualCash,
    this.expectedCash,
    this.cashRevenue,
    this.digitalRevenue,
    this.totalRevenue,
    required this.status,
    this.notes,
  });

  bool get isOpen => status == 'open';

  @override
  List<Object?> get props => [
        id,
        cashierId,
        cashierName,
        startTime,
        endTime,
        startingCash,
        actualCash,
        expectedCash,
        cashRevenue,
        digitalRevenue,
        totalRevenue,
        status,
        notes,
      ];
}
