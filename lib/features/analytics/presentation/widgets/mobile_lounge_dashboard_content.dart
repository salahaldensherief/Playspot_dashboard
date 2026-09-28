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

class MobileLoungeDashboardContent extends StatelessWidget {
  final VoidCallback onRefresh;

  const MobileLoungeDashboardContent({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Priority 1: Shift Status Invariant (Immediate visibility for cashiers on mobile)
        const RepaintBoundary(child: OperationalShiftBanner()),
        SizedBox(height: 12.h),

        // Priority 2: Needs Attention & Pending Actions
        const RepaintBoundary(child: NeedsAttentionPanel()),
        SizedBox(height: 12.h),

        // Priority 3: Today Vital Numbers (Compact 2-col KPI grid)
        RepaintBoundary(
          child: CockpitKpiGrid(isSuperAdmin: false, onRetry: onRefresh),
        ),
        SizedBox(height: 12.h),

        // Priority 4: Active Gaming Sessions (Touch-friendly vertical cards)
        const RepaintBoundary(child: LiveBookingsFeed()),
        SizedBox(height: 12.h),

        // Priority 5: Quick Actions (Touch-friendly >= 48px targets)
        const QuickActionsCard(isSuperAdmin: false),
        SizedBox(height: 12.h),

        // Priority 6: Revenue Intelligence
        const RepaintBoundary(child: RevenueIntelligenceCard()),
        SizedBox(height: 12.h),

        // Priority 7: Growth Opportunities
        const RepaintBoundary(child: GrowthOpportunitiesPanel()),
        SizedBox(height: 12.h),

        // Priority 8: Room Status
        const RepaintBoundary(child: RoomStatusCard()),
        SizedBox(height: 12.h),

        // Priority 9: PlaySpot OS Capabilities & Modules Launchpad
        const RepaintBoundary(child: LoungeCapabilitiesGrid()),
        SizedBox(height: 12.h),

        // Priority 10: Recent Activity
        const RepaintBoundary(child: RecentActivityCard()),
        SizedBox(height: 12.h),

        // Priority 11: Charts
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
        SizedBox(
          height: 220.h,
          child: ChartCard(
            title: AppStrings.roomUtilization,
            subtitle: AppStrings.capacityTracking,
            actionIcon: Icons.pie_chart_outline,
            actionIconColor: AppColors.neonPurple,
            chart: const RepaintBoundary(child: UtilizationChart()),
          ),
        ),
      ],
    );
  }
}
