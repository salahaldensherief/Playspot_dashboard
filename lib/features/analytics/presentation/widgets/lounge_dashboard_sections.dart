import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/room_status_card.dart';
import 'chart_card.dart';
import 'cockpit_kpi_grid.dart';
import 'dashboard_flow_layout.dart';
import 'growth_opportunities_panel.dart';
import 'live_bookings_feed.dart';
import 'lounge_capabilities_grid.dart';
import 'needs_attention_panel.dart';
import 'quick_actions.dart';
import 'recent_activities.dart';
import 'revenue_chart.dart';
import 'revenue_intelligence_card.dart';

class LoungeDashboardSections extends StatelessWidget {
  const LoungeDashboardSections({super.key, required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isCashier =
        context.watch<LoginCubit>().state.user?.isCashier ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          child: CockpitKpiGrid(isSuperAdmin: false, onRetry: onRefresh),
        ),
        const SizedBox(height: DashboardFlowLayout.gap),
        DashboardFlowLayout(
          compact: [
            const RepaintBoundary(child: NeedsAttentionPanel()),
            const RepaintBoundary(child: LiveBookingsFeed()),
            const QuickActionsCard(isSuperAdmin: false),
            const RepaintBoundary(child: RoomStatusCard()),
            if (!isCashier)
              const RepaintBoundary(child: RevenueIntelligenceCard()),
            const RepaintBoundary(child: RecentActivityCard()),
            if (!isCashier) ...[
              const RepaintBoundary(child: GrowthOpportunitiesPanel()),
              ChartCard(
                expandChart: false,
                title: AppStrings.revenueAnalytics,
                subtitle: AppStrings.weeklyPerformance,
                actionIcon: Icons.trending_up,
                actionIconColor: AppColors.success,
                chart: const RepaintBoundary(child: RevenueChart()),
              ),
            ],
          ],
          main: [
            const RepaintBoundary(child: NeedsAttentionPanel()),
            const RepaintBoundary(child: LiveBookingsFeed()),
            if (!isCashier) ...[
              const RepaintBoundary(child: RevenueIntelligenceCard()),
              ChartCard(
                expandChart: false,
                title: AppStrings.revenueAnalytics,
                subtitle: AppStrings.weeklyPerformance,
                actionIcon: Icons.trending_up,
                actionIconColor: AppColors.success,
                chart: const RepaintBoundary(child: RevenueChart()),
              ),
            ],
            const RepaintBoundary(child: RecentActivityCard()),
          ],
          aside: [
            const QuickActionsCard(isSuperAdmin: false),
            const RepaintBoundary(child: RoomStatusCard()),
            if (!isCashier) ...[
              const RepaintBoundary(child: GrowthOpportunitiesPanel()),
            ],
          ],
        ),
        if (!isCashier) ...[
          const SizedBox(height: DashboardFlowLayout.gap),
          const RepaintBoundary(child: LoungeCapabilitiesGrid()),
        ],
      ],
    );
  }
}
