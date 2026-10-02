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
    super.activeSessions,
    super.closedBookings,
  });

  factory LiveShiftOverviewModel.fromJson(Map<String, dynamic> json) {
    final rawAvatar = json['cashier_avatar']?.toString();
    final avatar = (rawAvatar != null && rawAvatar.trim().isNotEmpty)
        ? rawAvatar.trim()
        : null;

    final rawName =
        json['cashier_name']?.toString() ??
        json['cashier_full_name']?.toString() ??
        json['cashier']?.toString() ??
        json['staff_name']?.toString();

    return LiveShiftOverviewModel(
      hasActiveShift: json['has_active_shift'] ?? false,
      shiftId: json['shift_id']?.toString(),
      cashierName: (rawName != null && rawName.trim().isNotEmpty)
          ? rawName.trim()
          : 'N/A',
      cashierAvatar: avatar,
      cashierPhone: json['cashier_phone']?.toString(),
      startTime: DateTime.tryParse(
        (json['opened_at'] ?? json['start_time'] ?? '').toString(),
      ),
      startingCash: (json['starting_cash'] ?? json['opening_cash'])?.toDouble(),
      cashInDrawer:
          (json['expected_cash'] ??
                  json['cash_in_drawer'] ??
                  json['actual_cash_counted'])
              ?.toDouble(),
      digitalPayments: (json['digital_sales'] ?? json['digital_payments'])
          ?.toDouble(),
      activeSessions: (json['active_sessions'] as num?)?.toInt(),
      closedBookings: (json['closed_bookings'] as num?)?.toInt(),
    );
  }
}
