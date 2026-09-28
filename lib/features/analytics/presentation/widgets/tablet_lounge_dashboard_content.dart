import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
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

class TabletLoungeDashboardContent extends StatelessWidget {
  final VoidCallback onRefresh;

  const TabletLoungeDashboardContent({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 0. Shift Invariant / Operational Status
        const RepaintBoundary(child: OperationalShiftBanner()),
        SizedBox(height: 14.h),

        // 1. Cockpit KPI Grid (2 or 3 columns on tablet)
        RepaintBoundary(
          child: CockpitKpiGrid(isSuperAdmin: false, onRetry: onRefresh),
        ),
        SizedBox(height: 14.h),

        // 2. Needs Attention & Quick Actions (Two-column layout)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: RepaintBoundary(child: NeedsAttentionPanel()),
            ),
            SizedBox(width: 14.w),
            const Expanded(child: QuickActionsCard(isSuperAdmin: false)),
          ],
        ),
        SizedBox(height: 14.h),

        // 3. Growth Opportunities Panel
        const RepaintBoundary(child: GrowthOpportunitiesPanel()),
        SizedBox(height: 14.h),

        // 4. Live Sessions & Operations
        const RepaintBoundary(child: LiveBookingsFeed()),
        SizedBox(height: 14.h),

        // 5. Room Status Card
        const RepaintBoundary(child: RoomStatusCard()),
        SizedBox(height: 14.h),

        // 6. Revenue Intelligence Card
        const RepaintBoundary(child: RevenueIntelligenceCard()),
        SizedBox(height: 14.h),

        // 7. Analytics Charts (Two Columns)
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
            Expanded(
              child: SizedBox(
                height: 230.h,
                child: ChartCard(
                  title: AppStrings.roomUtilization,
                  subtitle: AppStrings.capacityTracking,
                  actionIcon: Icons.pie_chart_outline,
                  actionIconColor: AppColors.neonPurple,
                  chart: const RepaintBoundary(child: UtilizationChart()),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // 8. Recent Activity
        const RepaintBoundary(child: RecentActivityCard()),
        SizedBox(height: 14.h),

        // 9. PlaySpot OS Capabilities & Modules Launchpad
        const RepaintBoundary(child: LoungeCapabilitiesGrid()),
      ],
    );
  }
}
