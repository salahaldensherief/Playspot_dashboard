import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/stat_card.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';

class DashboardStatsGrid extends StatelessWidget {
  final bool isSuperAdmin;

  const DashboardStatsGrid({super.key, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final bool canViewRevenue = user?.canViewFinancials ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int crossAxisCount = 5;
        if (width < 800) {
          crossAxisCount = 2;
        } else if (width < 1200) {
          crossAxisCount = 3;
        }

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          addSemanticIndexes: false,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            mainAxisExtent: 130.h.clamp(110.0, 160.0),
          ),
          children: [
            if (canViewRevenue)
              BlocSelector<DashboardCubit, DashboardState, (double, double)>(
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
            BlocSelector<DashboardCubit, DashboardState, (int, double)>(
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
            BlocSelector<DashboardCubit, DashboardState, (double, double)>(
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
            BlocSelector<DashboardCubit, DashboardState, (String, double, int)>(
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
            BlocSelector<DashboardCubit, DashboardState, double>(
              selector: (state) => state.totalPlayHours,
              builder: (context, hours) {
                return StatCard(
                  title: AppStrings.playHours,
                  value: '${hours.toStringAsFixed(0)}h',
                  trendValue: 0.0,
                  icon: Icons.timer_outlined,
                  iconColor: Colors.orangeAccent,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
