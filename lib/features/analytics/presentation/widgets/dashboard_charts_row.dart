import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/revenue_chart.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'chart_card.dart';
import 'utilization_chart.dart';
import 'quick_actions.dart';

class DashboardChartsRow extends StatelessWidget {
  const DashboardChartsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final bool canViewRevenue = user?.canViewFinancials ?? false;
    final bool isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          if (canViewRevenue)
            SizedBox(
              height: 350.h,
              child: ChartCard(
                title: AppStrings.revenueAnalytics,
                subtitle: AppStrings.weeklyPerformance,
                actionIcon: Icons.trending_up,
                actionIconColor: AppColors.success,
                chart: const RevenueChart(),
              ),
            ),
          if (canViewRevenue) SizedBox(height: 24.h),
          SizedBox(
            height: 350.h,
            child: ChartCard(
              title: AppStrings.roomUtilization,
              subtitle: AppStrings.capacityTracking,
              actionIcon: Icons.pie_chart_outline,
              actionIconColor: AppColors.neonPurple,
              chart: const UtilizationChart(),
            ),
          ),
          SizedBox(height: 24.h),
          const QuickActionsCard(),
        ],
      );
    }

    return SizedBox(
      height: 350.h,
      child: Row(
        children: [
          if (canViewRevenue)
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
          if (canViewRevenue) SizedBox(width: 24.w),
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
