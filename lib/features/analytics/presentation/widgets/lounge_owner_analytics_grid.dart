import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/stat_card.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import '../cubit/lounge_stats_cubit.dart';
import '../cubit/lounge_stats_state.dart';
import 'occupancy_gauge_card.dart';
import 'status_alerts_card.dart';

class LoungeOwnerAnalyticsGrid extends StatelessWidget {
  const LoungeOwnerAnalyticsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoungeStatsCubit, LoungeStatsState>(
      buildWhen: (prev, curr) => prev.status != curr.status || prev.stats != curr.stats,
      builder: (context, state) {
        if (state.status == LoungeStatsStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }

        if (state.status == LoungeStatsStatus.failure) {
          return Center(child: Text(state.errorMessage ?? AppStrings.error, style: const TextStyle(color: AppColors.danger)));
        }

        final stats = state.stats;
        if (stats == null) return const SizedBox.shrink();

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Responsive.isMobile(context)
                ? 1
                : Responsive.isTablet(context)
                    ? 2
                    : 4,
            crossAxisSpacing: 20.w,
            mainAxisSpacing: 20.h,
            mainAxisExtent: 180.h,
          ),
          children: [
            // Today's Revenue
            StatCard(
              title: AppStrings.dailyTotal,
              value: '${stats.todayRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
              trendValue: 0.0,
              subtitle: AppStrings.dailyRevenue,
              icon: Icons.today_outlined,
              iconColor: AppColors.neonGreen,
            ),

            // Monthly Revenue
            StatCard(
              title: AppStrings.totalRevenue,
              value: '${stats.monthlyRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
              trendValue: 0.0,
              subtitle: AppStrings.revenueAnalytics,
              icon: Icons.calendar_month_outlined,
              iconColor: AppColors.neonCyan,
            ),

            // Room Occupancy Gauge
            OccupancyGaugeCard(
              occupied: stats.occupiedRooms,
              total: stats.totalRooms,
              rate: stats.occupancyRate,
            ),

            // Status Alerts (Shifts & Stock)
            StatusAlertsCard(
              openShifts: stats.openShifts,
              lowStock: stats.lowStockItems,
            ),
          ],
        );
      },
    );
  }
}
