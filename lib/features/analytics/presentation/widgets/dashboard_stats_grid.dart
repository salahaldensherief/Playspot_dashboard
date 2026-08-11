import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/stat_card.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';

class DashboardStatsGrid extends StatelessWidget {
  final bool isSuperAdmin;

  const DashboardStatsGrid({super.key, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.status == FeatureStatus.loading && state.totalRevenue == 0) {
           return const Center(child: CircularProgressIndicator());
        }

        return Row(
          children: [
            Expanded(
              child: StatCard(
                title: isSuperAdmin ? 'Global Revenue' : AppStrings.dailyRevenue,
                value: '\$${state.totalRevenue.toStringAsFixed(0)}',
                trendValue: state.revenueTrend,
                icon: Icons.payments_outlined,
                iconColor: AppColors.neonGreen,
              ),
            ),
            SizedBox(width: 24.w),
            Expanded(
              child: StatCard(
                title: isSuperAdmin ? 'Total Bookings' : AppStrings.activeSessions,
                value: isSuperAdmin ? state.totalBookings.toString() : state.activeSessions.toString(),
                trendValue: state.bookingsTrend,
                icon: Icons.sports_esports_outlined,
                iconColor: AppColors.neonBlue,
              ),
            ),
            SizedBox(width: 24.w),
            Expanded(
              child: StatCard(
                title: AppStrings.loungeOccupancy,
                value: '${(state.occupancyRate * 100).toStringAsFixed(0)}%',
                trendValue: state.occupancyTrend,
                icon: Icons.meeting_room_outlined,
                iconColor: AppColors.neonPurple,
              ),
            ),
            SizedBox(width: 24.w),
            Expanded(
              child: StatCard(
                title: isSuperAdmin ? 'Lounges Online' : 'Active Rooms',
                value: isSuperAdmin 
                  ? '${state.activeLounges}/${state.totalLounges}' 
                  : '${state.activeRoomsCount}',
                trendValue: state.loungesTrend,
                subtitle: isSuperAdmin ? '${state.totalUsers} Total Users' : AppStrings.systemHealth,
                icon: isSuperAdmin ? Icons.business : Icons.door_front_door,
                iconColor: AppColors.neonCyan,
              ),
            ),
          ],
        );
      },
    );
  }
}
