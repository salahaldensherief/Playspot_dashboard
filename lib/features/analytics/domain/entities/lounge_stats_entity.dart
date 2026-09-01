import 'package:equatable/equatable.dart';

class LoungeStatsEntity extends Equatable {
  final bool success;
  final String loungeId;
  final double todayRevenue;
  final double monthlyRevenue;
  final int totalRooms;
  final int occupiedRooms;
  final double occupancyRate;
  final int activeBookings;
  final int openShifts;
  final int lowStockItems;

  const LoungeStatsEntity({
    required this.success,
    required this.loungeId,
    required this.todayRevenue,
    required this.monthlyRevenue,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.occupancyRate,
    required this.activeBookings,
    required this.openShifts,
    required this.lowStockItems,
  });

  @override
  List<Object?> get props => [
        success,
        loungeId,
        todayRevenue,
        monthlyRevenue,
        totalRooms,
        occupiedRooms,
        occupancyRate,
        activeBookings,
        openShifts,
        lowStockItems,
      ];
}
