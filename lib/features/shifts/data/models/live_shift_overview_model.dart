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

    final rawName = json['cashier_name']?.toString() ??
        json['cashier_full_name']?.toString() ??
        json['cashier']?.toString() ??
        json['staff_name']?.toString();

    return LiveShiftOverviewModel(
      hasActiveShift: json['has_active_shift'] ?? false,
      shiftId: json['shift_id']?.toString(),
      cashierName: (rawName != null && rawName.trim().isNotEmpty) ? rawName.trim() : 'N/A',
      cashierAvatar: avatar,
      cashierPhone: json['cashier_phone']?.toString(),
      startTime: json['start_time'] != null ? DateTime.tryParse(json['start_time'].toString()) : null,
      startingCash: (json['starting_cash'] ?? json['opening_cash'] ?? 0).toDouble(),
      cashInDrawer: (json['actual_cash_counted'] ?? json['cash_in_drawer'] ?? 0).toDouble(),
      digitalPayments: (json['digital_payments'] ?? 0).toDouble(),
      activeSessions: json['active_sessions'] ?? 0,
      closedBookings: json['closed_bookings'] ?? 0,
    );
  }
}
