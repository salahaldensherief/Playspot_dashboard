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
    final rawAvatar = json['cashier_avatar']?.toString();
    final avatar = (rawAvatar != null && rawAvatar.trim().isNotEmpty) ? rawAvatar.trim() : null;

    return LiveShiftOverviewModel(
      hasActiveShift: json['has_active_shift'] ?? false,
      shiftId: json['shift_id']?.toString(),
      cashierName: json['cashier_name'],
      cashierAvatar: avatar,
      cashierPhone: json['cashier_phone'],
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      startingCash: (json['starting_cash'] ?? json['opening_cash'] ?? 0).toDouble(),
      cashInDrawer: (json['actual_cash_counted'] ?? json['cash_in_drawer'] ?? 0).toDouble(),
      digitalPayments: (json['digital_payments'] ?? 0).toDouble(),
      activeSessions: json['active_sessions'] ?? 0,
      closedBookings: json['closed_bookings'] ?? 0,
    );
  }
}
