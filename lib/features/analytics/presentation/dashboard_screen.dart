import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/chart_card.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/dashboard_section.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/dashboard_time_range_selector.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/revenue_chart.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/utilization_chart.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/shift_header_banner.dart';
import 'dashboard_cubit.dart';
import 'lounge_stats_cubit.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_stats_grid.dart';
import 'widgets/lounge_owner_analytics_grid.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_activities.dart';
import 'widgets/top_lounges_card.dart';

/// Analytical Layer Only DashboardScreen (KPIs, Charts, Recent Activity).
/// Uses Sliver-based DashboardSectionLayout and compact Sized charts to prevent scrolling.
class DashboardScreen extends StatefulWidget {
  final UserRole role;

  const DashboardScreen({
    super.key,
    required this.role,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardTimeRange _selectedTimeRange = DashboardTimeRange.week;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final loungeId = context.read<LoginCubit>().state.user?.loungeId;
      _initRealtimeStreams(loungeId);
    });
  }

  void _initRealtimeStreams(String? loungeId) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    if (widget.role != UserRole.superAdmin) {
      context.read<LoungeStatsCubit>().fetchStats(cleanLoungeId);
      context.read<DashboardCubit>().startWatchingActiveSessions(loungeId: cleanLoungeId);
      context.read<BookingCubit>().startWatchingBookings(loungeId: cleanLoungeId);
      if (cleanLoungeId != null) {
        context.read<RoomCubit>().watchRooms(cleanLoungeId);
        context.read<ClientRequestsCubit>().startWatchingRequests(loungeId: cleanLoungeId);
      }
    } else {
      context.read<DashboardCubit>().loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = widget.role == UserRole.superAdmin;

    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (prev, curr) => prev.user?.loungeId != curr.user?.loungeId,
      listener: (context, loginState) {
        final loungeId = loginState.user?.loungeId;
        _initRealtimeStreams(loungeId);
      },
      child: DashboardLayout(
        title: AppStrings.dashboard,
        activeRoute: 'Dashboard',
        isScrollable: false,
        child: isSuperAdmin
            ? _SuperAdminDashboardView(
                timeRange: _selectedTimeRange,
                onTimeRangeChanged: (range) => setState(() => _selectedTimeRange = range),
              )
            : _LoungeOwnerDashboardView(
                timeRange: _selectedTimeRange,
                onTimeRangeChanged: (range) => setState(() => _selectedTimeRange = range),
              ),
      ),
    );
  }
}

class _SuperAdminDashboardView extends StatelessWidget {
  final DashboardTimeRange timeRange;
  final ValueChanged<DashboardTimeRange> onTimeRangeChanged;

  const _SuperAdminDashboardView({
    required this.timeRange,
    required this.onTimeRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sections = [
      const DashboardSection(
        priority: 1,
        span: DashboardSpan.full,
        widget: RepaintBoundary(child: DashboardStatsGrid(isSuperAdmin: true)),
      ),
      DashboardSection(
        priority: 2,
        span: DashboardSpan.twoThirds,
        widget: SizedBox(
          height: 220.h,
          child: ChartCard(
            title: AppStrings.revenueAnalytics,
            subtitle: AppStrings.weeklyPerformance,
            actionIcon: Icons.trending_up,
            actionIconColor: AppColors.success,
            chart: const RepaintBoundary(child: RevenueChart()),
          ),
        ),
      ),
      const DashboardSection(
        priority: 3,
        span: DashboardSpan.oneThird,
        widget: QuickActionsCard(isSuperAdmin: true),
      ),
      const DashboardSection(
        priority: 4,
        span: DashboardSpan.twoThirds,
        widget: RepaintBoundary(child: TopLoungesCard()),
      ),
      const DashboardSection(
        priority: 5,
        span: DashboardSpan.oneThird,
        widget: RepaintBoundary(child: RecentActivityCard()),
      ),
    ];

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
          DashboardSectionLayout(sections: sections),
        ],
      ),
    );
  }
}

class _LoungeOwnerDashboardView extends StatelessWidget {
  final DashboardTimeRange timeRange;
  final ValueChanged<DashboardTimeRange> onTimeRangeChanged;

  const _LoungeOwnerDashboardView({
    required this.timeRange,
    required this.onTimeRangeChanged,
  });

  Future<void> _handleRefresh(BuildContext context) async {
    final loungeId = context.read<LoginCubit>().state.user?.loungeId;
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    await context.read<LoungeStatsCubit>().fetchStats(cleanLoungeId);
    if (context.mounted) {
      context.read<DashboardCubit>().startWatchingActiveSessions(loungeId: cleanLoungeId, forceRefresh: true);
      context.read<BookingCubit>().startWatchingBookings(loungeId: cleanLoungeId, forceRefresh: true);
      if (cleanLoungeId != null) {
        context.read<RoomCubit>().watchRooms(cleanLoungeId, forceRefresh: true);
        context.read<ClientRequestsCubit>().startWatchingRequests(loungeId: cleanLoungeId, forceRefresh: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      const DashboardSection(
        priority: 1,
        span: DashboardSpan.full,
        widget: RepaintBoundary(child: LoungeOwnerAnalyticsGrid()),
      ),
      DashboardSection(
        priority: 2,
        span: DashboardSpan.twoThirds,
        widget: SizedBox(
          height: 220.h,
          child: ChartCard(
            title: AppStrings.revenueAnalytics,
            subtitle: AppStrings.weeklyPerformance,
            actionIcon: Icons.trending_up,
            actionIconColor: AppColors.success,
            chart: const RepaintBoundary(child: RevenueChart()),
          ),
        ),
      ),
      const DashboardSection(
        priority: 3,
        span: DashboardSpan.oneThird,
        widget: QuickActionsCard(isSuperAdmin: false),
      ),
      DashboardSection(
        priority: 4,
        span: DashboardSpan.twoThirds,
        widget: SizedBox(
          height: 220.h,
          child: ChartCard(
            title: AppStrings.roomUtilization,
            subtitle: AppStrings.capacityTracking,
            actionIcon: Icons.pie_chart_outline,
            actionIconColor: AppColors.neonPurple,
            chart: const RepaintBoundary(child: UtilizationChart()),
          ),
        ),
      ),
      const DashboardSection(
        priority: 5,
        span: DashboardSpan.oneThird,
        widget: RepaintBoundary(child: RecentActivityCard()),
      ),
    ];

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(context),
      color: AppColors.neonBlue,
      backgroundColor: AppColors.cardBackground,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: ShiftHeaderBanner(),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 12.h)),
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DashboardHeader(
                    isSuperAdmin: false,
                    onRefresh: () => _handleRefresh(context),
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
          DashboardSectionLayout(sections: sections),
        ],
      ),
    );
  }
}
