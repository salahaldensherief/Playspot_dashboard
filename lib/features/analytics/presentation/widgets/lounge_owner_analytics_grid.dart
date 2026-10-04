import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/art_core/widgets/stat_card.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import '../lounge_stats_cubit.dart';
import '../lounge_stats_state.dart';
import 'occupancy_gauge_card.dart';
import 'status_alerts_card.dart';

class LoungeOwnerAnalyticsGrid extends StatelessWidget {
  const LoungeOwnerAnalyticsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return BlocBuilder<LoungeStatsCubit, LoungeStatsState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.stats != curr.stats,
      builder: (context, state) {
        final crossAxisCount = Responsive.isMobile(context)
            ? 1
            : (Responsive.isTablet(context) ? 2 : 4);
        final extent = 130.h.clamp(110.0, 160.0);

        if (state.status == LoungeStatsStatus.loading ||
            (state.stats == null &&
                state.status != LoungeStatsStatus.failure)) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            addSemanticIndexes: false,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              mainAxisExtent: extent,
            ),
            itemCount: 4,
            itemBuilder: (context, index) =>
                ShimmerLoading.rounded(height: extent, width: double.infinity),
          );
        }

        if (state.status == LoungeStatsStatus.failure && state.stats == null) {
          return Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.danger, size: 24.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    state.errorMessage ?? AppStrings.failedToLoadStats,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          );
        }

        final stats = state.stats!;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          addSemanticIndexes: false,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Responsive.isMobile(context)
                ? 1
                : Responsive.isTablet(context)
                ? 2
                : 4,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            mainAxisExtent: 130.h.clamp(110.0, 160.0),
          ),
          children: [
            // Today's Revenue
            StatCard(
              title: AppStrings.dailyTotal,
              value:
                  '${stats.todayRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
              trendValue: 0.0,
              subtitle: AppStrings.dailyRevenue,
              icon: Icons.today_outlined,
              iconColor: AppColors.neonGreen,
            ),

            // Monthly Revenue
            StatCard(
              title: AppStrings.totalRevenue,
              value:
                  '${stats.monthlyRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
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
