import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'dashboard_flow_layout.dart';
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
    EasyLocalization.of(context);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardHeader(
                  isSuperAdmin: true,
                  onRefresh: () =>
                      context.read<DashboardCubit>().loadDashboardData(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'revenue_chart_grouping'.tr(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    DashboardTimeRangeSelector(
                      selectedRange: timeRange,
                      onRangeChanged: onTimeRangeChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          SliverToBoxAdapter(
            child: _SuperAdminContent(
              onRefresh: () =>
                  context.read<DashboardCubit>().loadDashboardData(),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }
}

class _SuperAdminContent extends StatelessWidget {
  const _SuperAdminContent({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RepaintBoundary(
        child: CockpitKpiGrid(isSuperAdmin: true, onRetry: onRefresh),
      ),
      const SizedBox(height: 16),
      DashboardFlowLayout(
        main: [
          const RepaintBoundary(child: TopLoungesCard()),
          SizedBox(
            height:
                320 *
                (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1, 1.6),
            child: ChartCard(
              title: AppStrings.revenueAnalytics,
              subtitle: 'revenue_chart_grouping'.tr(),
              actionIcon: Icons.trending_up,
              actionIconColor: AppColors.success,
              chart: const RepaintBoundary(child: RevenueChart()),
            ),
          ),
        ],
        aside: const [
          QuickActionsCard(isSuperAdmin: true),
          RepaintBoundary(child: RecentActivityCard(isSuperAdmin: true)),
        ],
      ),
    ],
  );
}
