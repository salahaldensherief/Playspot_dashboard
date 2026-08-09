import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'chart_card.dart';
import 'utilization_chart.dart';
import 'quick_actions.dart';

class DashboardChartsRow extends StatelessWidget {
  const DashboardChartsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350.h,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ChartCard(
              title: AppStrings.revenueAnalytics,
              subtitle: AppStrings.weeklyPerformance,
              actionIcon: Icons.trending_up,
              actionIconColor: AppColors.success,
              chart: const RevenueChart(),
            ),
          ),
          SizedBox(width: 24.w),
          Expanded(
            flex: 1,
            child: ChartCard(
              title: AppStrings.roomUtilization,
              subtitle: AppStrings.capacityTracking,
              actionIcon: Icons.pie_chart_outline,
              actionIconColor: AppColors.neonPurple,
              chart: const UtilizationChart(),
            ),
          ),
          SizedBox(width: 24.w),
          const Expanded(
            flex: 1,
            child: QuickActionsCard(),
          ),
        ],
      ),
    );
  }
}
