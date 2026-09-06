import '../../domain/entities/live_shift_overview_entity.dart';

class LiveShiftOverviewModel extends LiveShiftOverviewEntity {
  const LiveShiftOverviewModel({
    required super.hasActiveShift,
    super.shiftId,
    super.cashierName,
    super.cashierAvatar,
    super.cashierPhone,
    super.startTime,
    super.startingCash,
    super.cashInDrawer,
    super.digitalPayments,
    super.activeSessions = 0,
    super.closedBookings = 0,
  });

  factory LiveShiftOverviewModel.fromJson(Map<String, dynamic> json) {
    return LiveShiftOverviewModel(
      hasActiveShift: json['has_active_shift'] ?? false,
      shiftId: json['shift_id']?.toString(),
      cashierName: json['cashier_name'],
      cashierAvatar: json['cashier_avatar'],
      cashierPhone: json['cashier_phone'],
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      startingCash: (json['starting_cash'] ?? json['opening_cash'] ?? 0).toDouble(),
      cashInDrawer: (json['cash_in_drawer'] ?? 0).toDouble(),
      digitalPayments: (json['digital_payments'] ?? 0).toDouble(),
      activeSessions: json['active_sessions'] ?? 0,
      closedBookings: json['closed_bookings'] ?? 0,
    );
  }
}
