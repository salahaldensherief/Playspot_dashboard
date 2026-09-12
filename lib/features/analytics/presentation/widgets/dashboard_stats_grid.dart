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
          children: isSuperAdmin
              ? [
                  if (canViewRevenue)
                    BlocSelector<DashboardCubit, DashboardState, (double, double)>(
                      selector: (state) => (state.totalRevenue, state.revenueTrend),
                      builder: (context, data) {
                        return StatCard(
                          title: AppStrings.globalOverview,
                          value: '\$${data.$1.toStringAsFixed(0)}',
                          trendValue: data.$2,
                          icon: Icons.payments_outlined,
                          iconColor: AppColors.neonGreen,
                        );
                      },
                    ),
                  BlocSelector<DashboardCubit, DashboardState, (int, int, double)>(
                    selector: (state) => (state.totalBookings, state.bookingsToday, state.bookingsTrend),
                    builder: (context, data) {
                      return StatCard(
                        title: AppStrings.bookingsLabel,
                        value: data.$1.toString(),
                        trendValue: data.$3,
                        subtitle: '${data.$2} ${AppStrings.today}',
                        icon: Icons.sports_esports_outlined,
                        iconColor: AppColors.neonBlue,
                      );
                    },
                  ),
                  BlocSelector<DashboardCubit, DashboardState, (int, int, double)>(
                    selector: (state) => (state.activeLounges, state.totalLounges, state.loungesTrend),
                    builder: (context, data) {
                      return StatCard(
                        title: AppStrings.lounges,
                        value: '${data.$1}/${data.$2}',
                        trendValue: data.$3,
                        icon: Icons.business_outlined,
                        iconColor: AppColors.neonCyan,
                      );
                    },
                  ),
                  BlocSelector<DashboardCubit, DashboardState, double>(
                    selector: (state) => state.totalPlatformCommission,
                    builder: (context, commission) {
                      return StatCard(
                        title: AppStrings.payouts,
                        value: '\$${commission.toStringAsFixed(0)}',
                        trendValue: 0.0,
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: AppColors.neonPurple,
                      );
                    },
                  ),
                  BlocSelector<DashboardCubit, DashboardState, int>(
                    selector: (state) => state.totalUsers,
                    builder: (context, users) {
                      return StatCard(
                        title: AppStrings.users,
                        value: users.toString(),
                        trendValue: 0.0,
                        icon: Icons.people_outline,
                        iconColor: Colors.orangeAccent,
                      );
                    },
                  ),
                ]
              : [
                  if (canViewRevenue)
                    BlocSelector<DashboardCubit, DashboardState, (double, double)>(
                      selector: (state) => (state.totalRevenue, state.revenueTrend),
                      builder: (context, data) {
                        return StatCard(
                          title: AppStrings.dailyRevenue,
                          value: '\$${data.$1.toStringAsFixed(0)}',
                          trendValue: data.$2,
                          icon: Icons.payments_outlined,
                          iconColor: AppColors.neonGreen,
                        );
                      },
                    ),
                  BlocSelector<DashboardCubit, DashboardState, (int, double)>(
                    selector: (state) => (state.activeSessions, state.bookingsTrend),
                    builder: (context, data) {
                      return StatCard(
                        title: AppStrings.activeSessions,
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
                  BlocSelector<DashboardCubit, DashboardState, (int, double)>(
                    selector: (state) => (state.activeRoomsCount, state.loungesTrend),
                    builder: (context, data) {
                      return StatCard(
                        title: AppStrings.activeBookings,
                        value: data.$1.toString(),
                        trendValue: data.$2,
                        subtitle: AppStrings.systemHealth,
                        icon: Icons.door_front_door_outlined,
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
