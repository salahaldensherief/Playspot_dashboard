import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/room_status_card.dart';
import 'chart_card.dart';
import 'cockpit_kpi_grid.dart';
import 'growth_opportunities_panel.dart';
import 'live_bookings_feed.dart';
import 'lounge_capabilities_grid.dart';
import 'needs_attention_panel.dart';
import 'operational_shift_banner.dart';
import 'quick_actions.dart';
import 'recent_activities.dart';
import 'revenue_chart.dart';
import 'revenue_intelligence_card.dart';
import 'utilization_chart.dart';

class DesktopLoungeDashboardContent extends StatelessWidget {
  final VoidCallback onRefresh;

  const DesktopLoungeDashboardContent({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LoginCubit>().state.user;
    final isCashier = user?.isCashier ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 0. Shift Invariant / Operational Status
        const RepaintBoundary(child: OperationalShiftBanner()),
        SizedBox(height: 16.h),

        // 1. Cockpit Operational KPI Grid
        RepaintBoundary(
          child: CockpitKpiGrid(isSuperAdmin: false, onRetry: onRefresh),
        ),
        SizedBox(height: 16.h),

        // 2. Operational Attention & Growth Opportunities
        if (isCashier) ...[
          const RepaintBoundary(child: NeedsAttentionPanel()),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 6,
                child: RepaintBoundary(child: NeedsAttentionPanel()),
              ),
              SizedBox(width: 16.w),
              const Expanded(
                flex: 6,
                child: RepaintBoundary(child: GrowthOpportunitiesPanel()),
              ),
            ],
          ),
        ],
        SizedBox(height: 16.h),

        // 3. Live Active Operations Feed & Quick Actions
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 7,
              child: RepaintBoundary(child: LiveBookingsFeed()),
            ),
            SizedBox(width: 16.w),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  const QuickActionsCard(isSuperAdmin: false),
                  SizedBox(height: 16.h),
                  const RepaintBoundary(child: RoomStatusCard()),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // 4. Revenue Intelligence (Owner / Manager only)
        if (!isCashier) ...[
          const RepaintBoundary(child: RevenueIntelligenceCard()),
          SizedBox(height: 16.h),
        ],

        // 5. Analytics & Utilization Charts + Recent Activity
        if (!isCashier) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
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
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 240.h,
                  child: ChartCard(
                    title: AppStrings.roomUtilization,
                    subtitle: AppStrings.capacityTracking,
                    actionIcon: Icons.pie_chart_outline,
                    actionIconColor: AppColors.neonPurple,
                    chart: const RepaintBoundary(child: UtilizationChart()),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              const Expanded(
                flex: 4,
                child: RepaintBoundary(child: RecentActivityCard()),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ] else ...[
          const RepaintBoundary(child: RecentActivityCard()),
          SizedBox(height: 16.h),
        ],

        // 6. PlaySpot OS Capabilities & Modules Launchpad (Owner / Manager only)
        if (!isCashier)
          const RepaintBoundary(child: LoungeCapabilitiesGrid()),
      ],
    );
  }
}
