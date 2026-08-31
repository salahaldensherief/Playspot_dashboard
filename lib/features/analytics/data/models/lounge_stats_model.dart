import '../../domain/entities/lounge_stats_entity.dart';

class LoungeStatsModel extends LoungeStatsEntity {
  const LoungeStatsModel({
    required super.success,
    required super.loungeId,
    required super.todayRevenue,
    required super.monthlyRevenue,
    required super.totalRooms,
    required super.occupiedRooms,
    required super.occupancyRate,
    required super.activeBookings,
    required super.openShifts,
    required super.lowStockItems,
  });

  factory LoungeStatsModel.fromJson(Map<String, dynamic> json) {
    return LoungeStatsModel(
      success: json['success'] ?? false,
      loungeId: json['lounge_id'] ?? '',
      todayRevenue: (json['today_revenue'] as num?)?.toDouble() ?? 0.0,
      monthlyRevenue: (json['monthly_revenue'] as num?)?.toDouble() ?? 0.0,
      totalRooms: (json['total_rooms'] as num?)?.toInt() ?? 0,
      occupiedRooms: (json['occupied_rooms'] as num?)?.toInt() ?? 0,
      occupancyRate: (json['occupancy_rate'] as num?)?.toDouble() ?? 0.0,
      activeBookings: (json['active_bookings'] as num?)?.toInt() ?? 0,
      openShifts: (json['open_shifts'] as num?)?.toInt() ?? 0,
      lowStockItems: (json['low_stock_items'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'lounge_id': loungeId,
      'today_revenue': todayRevenue,
      'monthly_revenue': monthlyRevenue,
      'total_rooms': totalRooms,
      'occupied_rooms': occupiedRooms,
      'occupancy_rate': occupancyRate,
      'active_bookings': activeBookings,
      'open_shifts': openShifts,
      'low_stock_items': lowStockItems,
    };
  }
}
