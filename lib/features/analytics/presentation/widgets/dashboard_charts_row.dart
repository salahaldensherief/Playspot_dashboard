import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/revenue_chart.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'chart_card.dart';
import 'utilization_chart.dart';

class DashboardChartsRow extends StatelessWidget {
  const DashboardChartsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final bool canViewRevenue = user?.canViewFinancials ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool shouldStack = constraints.maxWidth < 600;

        if (shouldStack) {
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
              if (canViewRevenue) SizedBox(height: 20.h),
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
            ],
          );
        }

        return SizedBox(
          height: 400.h,
          child: Row(
            children: [
              if (canViewRevenue)
                Expanded(
                  child: ChartCard(
                    title: AppStrings.revenueAnalytics,
                    subtitle: AppStrings.weeklyPerformance,
                    actionIcon: Icons.trending_up,
                    actionIconColor: AppColors.success,
                    chart: const RevenueChart(),
                  ),
                ),
              if (canViewRevenue) SizedBox(width: 20.w),
              Expanded(
                child: ChartCard(
                  title: AppStrings.roomUtilization,
                  subtitle: AppStrings.capacityTracking,
                  actionIcon: Icons.pie_chart_outline,
                  actionIconColor: AppColors.neonPurple,
                  chart: const UtilizationChart(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
