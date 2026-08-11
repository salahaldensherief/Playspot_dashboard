import 'package:flutter_bloc/flutter_bloc.dart';
import '../../lounges/domain/repositories/lounge_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final LoungeRepository loungeRepository;
  
  DashboardCubit(this.loungeRepository) : super(DashboardState.init());

  Future<void> loadDashboardData({String? loungeId}) async {
    if (isClosed) return;
    emit(state.copyWith(status: FeatureStatus.loading));
    
    try {
      // Fetch common stats
      final statsResult = await loungeRepository.getDashboardStats(loungeId);
      
      statsResult.fold(
        (failure) => emit(state.copyWith(status: FeatureStatus.failure, errorMessage: failure.message)),
        (stats) async {
          DashboardState newState = state.copyWith(
            totalRevenue: (stats['total_revenue'] as num?)?.toDouble() ?? 0.0,
            activeSessions: (stats['active_sessions'] as num?)?.toInt() ?? 0,
            occupancyRate: (stats['occupancy_rate'] as num?)?.toDouble() ?? 0.0,
            activeRoomsCount: (stats['active_rooms_count'] as num?)?.toInt() ?? 0,
            revenueTrend: (stats['revenue_trend'] as num?)?.toDouble() ?? 0.0,
            bookingsTrend: (stats['bookings_trend'] as num?)?.toDouble() ?? 0.0,
            occupancyTrend: (stats['occupancy_trend'] as num?)?.toDouble() ?? 0.0,
          );

          // If Super Admin (no loungeId), fetch overview and charts
          if (loungeId == null) {
            final overviewResult = await loungeRepository.getDashboardOverview();
            final chartResult = await loungeRepository.getRevenueOverTime(30);
            final topResult = await loungeRepository.getTopLoungesByRevenue(10);

            overviewResult.fold(
              (failure) => null, // Silently fail for sub-data or handle as needed
              (overview) {
                newState = newState.copyWith(
                  totalLounges: (overview['total_lounges'] as num?)?.toInt() ?? 0,
                  activeLounges: (overview['active_lounges'] as num?)?.toInt() ?? 0,
                  totalUsers: (overview['total_users'] as num?)?.toInt() ?? 0,
                  totalBookings: (overview['total_bookings'] as num?)?.toInt() ?? 0,
                  bookingsToday: (overview['bookings_today'] as num?)?.toInt() ?? 0,
                  upcomingBookings: (overview['upcoming_bookings'] as num?)?.toInt() ?? 0,
                  completedBookings: (overview['completed_bookings'] as num?)?.toInt() ?? 0,
                  cancelledBookings: (overview['cancelled_bookings'] as num?)?.toInt() ?? 0,
                  pendingRevenue: (overview['pending_revenue'] as num?)?.toDouble() ?? 0.0,
                  totalPlatformCommission: (overview['total_platform_commission'] as num?)?.toDouble() ?? 0.0,
                );
              },
            );

            chartResult.fold((_) => null, (chart) => newState = newState.copyWith(revenueChart: chart));
            topResult.fold((_) => null, (top) => newState = newState.copyWith(topLounges: top));
          }

          emit(newState.copyWith(status: FeatureStatus.success));
        },
      );
    } catch (e) {
      emit(state.copyWith(status: FeatureStatus.failure, errorMessage: e.toString()));
    }
  }
}
