import 'package:equatable/equatable.dart';

enum FeatureStatus { initial, loading, success, failure;
  bool get isInitial => this == FeatureStatus.initial;
  bool get isLoading => this == FeatureStatus.loading;
  bool get isSuccess => this == FeatureStatus.success;
  bool get isFailure => this == FeatureStatus.failure;
}

class DashboardState extends Equatable {
  final FeatureStatus status;
  final String? errorMessage;
  
  // Lounge Stats
  final double totalRevenue;
  final int activeSessions;
  final double occupancyRate;
  final int activeRoomsCount;
  
  // Super Admin Overview
  final int totalLounges;
  final int activeLounges;
  final int totalUsers;
  final int totalBookings;
  final int bookingsToday;
  final int upcomingBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double pendingRevenue;
  final double totalPlatformCommission;

  // Chart Data
  final List<Map<String, dynamic>> revenueChart;
  final List<Map<String, dynamic>> topLounges;

  const DashboardState({
    this.status = FeatureStatus.initial,
    this.errorMessage,
    this.totalRevenue = 0,
    this.activeSessions = 0,
    this.occupancyRate = 0,
    this.activeRoomsCount = 0,
    this.totalLounges = 0,
    this.activeLounges = 0,
    this.totalUsers = 0,
    this.totalBookings = 0,
    this.bookingsToday = 0,
    this.upcomingBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.pendingRevenue = 0,
    this.totalPlatformCommission = 0,
    this.revenueChart = const [],
    this.topLounges = const [],
  });

  factory DashboardState.init() => const DashboardState();

  DashboardState copyWith({
    FeatureStatus? status,
    String? errorMessage,
    double? totalRevenue,
    int? activeSessions,
    double? occupancyRate,
    int? activeRoomsCount,
    int? totalLounges,
    int? activeLounges,
    int? totalUsers,
    int? totalBookings,
    int? bookingsToday,
    int? upcomingBookings,
    int? completedBookings,
    int? cancelledBookings,
    double? pendingRevenue,
    double? totalPlatformCommission,
    List<Map<String, dynamic>>? revenueChart,
    List<Map<String, dynamic>>? topLounges,
  }) => DashboardState(
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
    totalRevenue: totalRevenue ?? this.totalRevenue,
    activeSessions: activeSessions ?? this.activeSessions,
    occupancyRate: occupancyRate ?? this.occupancyRate,
    activeRoomsCount: activeRoomsCount ?? this.activeRoomsCount,
    totalLounges: totalLounges ?? this.totalLounges,
    activeLounges: activeLounges ?? this.activeLounges,
    totalUsers: totalUsers ?? this.totalUsers,
    totalBookings: totalBookings ?? this.totalBookings,
    bookingsToday: bookingsToday ?? this.bookingsToday,
    upcomingBookings: upcomingBookings ?? this.upcomingBookings,
    completedBookings: completedBookings ?? this.completedBookings,
    cancelledBookings: cancelledBookings ?? this.cancelledBookings,
    pendingRevenue: pendingRevenue ?? this.pendingRevenue,
    totalPlatformCommission: totalPlatformCommission ?? this.totalPlatformCommission,
    revenueChart: revenueChart ?? this.revenueChart,
    topLounges: topLounges ?? this.topLounges,
  );

  @override
  List<Object?> get props => [
    status, 
    errorMessage,
    totalRevenue,
    activeSessions,
    occupancyRate,
    activeRoomsCount,
    totalLounges,
    activeLounges,
    totalUsers,
    totalBookings,
    bookingsToday,
    upcomingBookings,
    completedBookings,
    cancelledBookings,
    pendingRevenue,
    totalPlatformCommission,
    revenueChart,
    topLounges,
  ];
}
