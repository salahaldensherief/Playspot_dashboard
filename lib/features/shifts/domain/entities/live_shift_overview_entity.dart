import 'package:equatable/equatable.dart';

class LiveShiftOverviewEntity extends Equatable {
  final bool hasActiveShift;
  final String? shiftId;
  final String? cashierName;
  final String? cashierAvatar;
  final String? cashierPhone;
  final DateTime? startTime;
  final double? startingCash;
  final double? cashInDrawer;
  final double? digitalPayments;
  final int activeSessions;
  final int closedBookings;

  const LiveShiftOverviewEntity({
    required this.hasActiveShift,
    this.shiftId,
    this.cashierName,
    this.cashierAvatar,
    this.cashierPhone,
    this.startTime,
    this.startingCash,
    this.cashInDrawer,
    this.digitalPayments,
    this.activeSessions = 0,
    this.closedBookings = 0,
  });

  @override
  List<Object?> get props => [
        hasActiveShift,
        shiftId,
        cashierName,
        cashierAvatar,
        cashierPhone,
        startTime,
        startingCash,
        cashInDrawer,
        digitalPayments,
        activeSessions,
        closedBookings,
      ];
}
