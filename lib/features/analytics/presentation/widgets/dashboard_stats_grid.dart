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
    return Row(
      children: [
        Expanded(
          child: BlocSelector<DashboardCubit, DashboardState, (double, double)>(
            selector: (state) => (state.totalRevenue, state.revenueTrend),
            builder: (context, data) {
              return StatCard(
                title: isSuperAdmin ? AppStrings.globalOverview : AppStrings.dailyRevenue,
                value: '\$${data.$1.toStringAsFixed(0)}',
                trendValue: data.$2,
                icon: Icons.payments_outlined,
                iconColor: AppColors.neonGreen,
              );
            },
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          child: BlocSelector<DashboardCubit, DashboardState, (int, double)>(
            selector: (state) => (isSuperAdmin ? state.totalBookings : state.activeSessions, state.bookingsTrend),
            builder: (context, data) {
              return StatCard(
                title: isSuperAdmin ? AppStrings.bookingsLabel : AppStrings.activeSessions,
                value: data.$1.toString(),
                trendValue: data.$2,
                icon: Icons.sports_esports_outlined,
                iconColor: AppColors.neonBlue,
              );
            },
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          child: BlocSelector<DashboardCubit, DashboardState, (double, double)>(
            selector: (state) => (state.occupancyRate, state.occupancyTrend),
            builder: (context, data) {
              return StatCard(
                title: AppStrings.loungeOccupancy,
                value: '${(data.$1 * 100).toStringAsFixed(0)}%',
                trendValue: data.$2,
                icon: Icons.meeting_room_outlined,
                iconColor: AppColors.neonPurple,
              );
            },
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          child: BlocSelector<DashboardCubit, DashboardState, (String, double, int)>(
            selector: (state) => (
              isSuperAdmin ? '${state.activeLounges}/${state.totalLounges}' : '${state.activeRoomsCount}',
              state.loungesTrend,
              state.totalUsers
            ),
            builder: (context, data) {
              return StatCard(
                title: isSuperAdmin ? AppStrings.lounges : AppStrings.activeBookings,
                value: data.$1,
                trendValue: data.$2,
                subtitle: isSuperAdmin ? '${data.$3} ${AppStrings.users}' : AppStrings.systemHealth,
                icon: isSuperAdmin ? Icons.business : Icons.door_front_door,
                iconColor: AppColors.neonCyan,
              );
            },
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          child: BlocSelector<DashboardCubit, DashboardState, double>(
            selector: (state) => state.totalPlayHours,
            builder: (context, hours) {
              return StatCard(
                title: AppStrings.playHours,
                value: '${hours.toStringAsFixed(0)}h',
                trendValue: 0.0, // Added missing required parameter
                icon: Icons.timer_outlined,
                iconColor: Colors.orangeAccent,
              );
            },
          ),
        ),
      ],
    );
  }
}
