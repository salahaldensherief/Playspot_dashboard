import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import '../dashboard_cubit.dart';
import 'chart_card.dart';
import 'cockpit_kpi_grid.dart';
import 'dashboard_header.dart';
import 'dashboard_time_range_selector.dart';
import 'quick_actions.dart';
import 'recent_activities.dart';
import 'revenue_chart.dart';
import 'top_lounges_card.dart';

class SuperAdminDashboardView extends StatelessWidget {
  final DashboardTimeRange timeRange;
  final ValueChanged<DashboardTimeRange> onTimeRangeChanged;

  const SuperAdminDashboardView({
    super.key,
    required this.timeRange,
    required this.onTimeRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<DashboardCubit>().loadDashboardData();
      },
      color: AppColors.neonBlue,
      backgroundColor: AppColors.cardBackground,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DashboardHeader(
                    isSuperAdmin: true,
                    onRefresh: () async {
                      await context.read<DashboardCubit>().loadDashboardData();
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                DashboardTimeRangeSelector(
                  selectedRange: timeRange,
                  onRangeChanged: onTimeRangeChanged,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          SliverToBoxAdapter(
            child: Responsive(
              mobile: _MobileSuperAdminContent(
                onRefresh: () =>
                    context.read<DashboardCubit>().loadDashboardData(),
              ),
              tablet: _TabletSuperAdminContent(
                onRefresh: () =>
                    context.read<DashboardCubit>().loadDashboardData(),
              ),
              desktop: _DesktopSuperAdminContent(
                onRefresh: () =>
                    context.read<DashboardCubit>().loadDashboardData(),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }
}

class _DesktopSuperAdminContent extends StatelessWidget {
  final VoidCallback onRefresh;

  const _DesktopSuperAdminContent({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          child: CockpitKpiGrid(isSuperAdmin: true, onRetry: onRefresh),
        ),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 7,
              child: RepaintBoundary(child: TopLoungesCard()),
            ),
            SizedBox(width: 16.w),
            const Expanded(
              flex: 5,
              child: QuickActionsCard(isSuperAdmin: true),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: SizedBox(
                height: 240.h,
                child: ChartCard(
                  title: AppStrings.revenueAnalytics,
                  subtitle: AppStrings.weeklyPerformance,
                  actionIcon: Icons.trending_up,
                  actionIconColor: AppColors.success,
                  chart: const RepaintBoundary(child: RevenueChart()),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            const Expanded(
              flex: 5,
              child: RepaintBoundary(child: RecentActivityCard()),
            ),
          ],
        ),
      ],
    );
  }
}

class _TabletSuperAdminContent extends StatelessWidget {
  final VoidCallback onRefresh;

  const _TabletSuperAdminContent({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          child: CockpitKpiGrid(isSuperAdmin: true, onRetry: onRefresh),
        ),
        SizedBox(height: 14.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: RepaintBoundary(child: TopLoungesCard())),
            SizedBox(width: 14.w),
            const Expanded(child: QuickActionsCard(isSuperAdmin: true)),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                height: 230.h,
                child: ChartCard(
                  title: AppStrings.revenueAnalytics,
                  subtitle: AppStrings.weeklyPerformance,
                  actionIcon: Icons.trending_up,
                  actionIconColor: AppColors.success,
                  chart: const RepaintBoundary(child: RevenueChart()),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            const Expanded(child: RepaintBoundary(child: RecentActivityCard())),
          ],
        ),
      ],
    );
  }
}

class _MobileSuperAdminContent extends StatelessWidget {
  final VoidCallback onRefresh;

  const _MobileSuperAdminContent({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          child: CockpitKpiGrid(isSuperAdmin: true, onRetry: onRefresh),
        ),
        SizedBox(height: 12.h),
        const QuickActionsCard(isSuperAdmin: true),
        SizedBox(height: 12.h),
        const RepaintBoundary(child: TopLoungesCard()),
        SizedBox(height: 12.h),
        SizedBox(
          height: 220.h,
          child: ChartCard(
            title: AppStrings.revenueAnalytics,
            subtitle: AppStrings.weeklyPerformance,
            actionIcon: Icons.trending_up,
            actionIconColor: AppColors.success,
            chart: const RepaintBoundary(child: RevenueChart()),
          ),
        ),
        SizedBox(height: 12.h),
        const RepaintBoundary(child: RecentActivityCard()),
      ],
    );
  }
}
