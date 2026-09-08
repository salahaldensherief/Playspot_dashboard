import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/chart_card.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/revenue_chart.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/utilization_chart.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/room_status_card.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/reviews/presentation/reviews_cubit.dart';
import 'package:play_spot_dashboard/features/reviews/presentation/widgets/lounge_reviews_card.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/shift_header_banner.dart';
import 'dashboard_cubit.dart';
import 'lounge_stats_cubit.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_stats_grid.dart';
import 'widgets/live_bookings_feed.dart';
import 'widgets/lounge_owner_analytics_grid.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_activities.dart';
import 'widgets/top_lounges_card.dart';

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
    if (widget.role != UserRole.superAdmin) {
      context.read<LoungeStatsCubit>().fetchStats(loungeId);
      context.read<DashboardCubit>().startWatchingActiveSessions(loungeId: loungeId);
      context.read<BookingCubit>().startWatchingBookings(loungeId: loungeId);
      if (loungeId != null && loungeId.isNotEmpty) {
        context.read<RoomCubit>().watchRooms(loungeId);
        context.read<ClientRequestsCubit>().startWatchingRequests(loungeId: loungeId);
        context.read<ReviewsCubit>().startWatchingReviews(loungeId: loungeId);
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
      child: isSuperAdmin
          ? const _SuperAdminDashboardView()
          : const _LoungeOwnerDashboardView(),
    );
  }
}

class _SuperAdminDashboardView extends StatelessWidget {
  const _SuperAdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1200;

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardHeader(isSuperAdmin: true),
              SizedBox(height: 20.h),
              const DashboardStatsGrid(isSuperAdmin: true),
              SizedBox(height: 20.h),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 380.h,
                            child: ChartCard(
                              title: AppStrings.revenueAnalytics,
                              subtitle: AppStrings.weeklyPerformance,
                              actionIcon: Icons.trending_up,
                              actionIconColor: AppColors.success,
                              chart: const RevenueChart(),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          const TopLoungesCard(),
                        ],
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          const QuickActionsCard(isSuperAdmin: true),
                          SizedBox(height: 20.h),
                          const RecentActivityCard(),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
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
                    SizedBox(height: 20.h),
                    const QuickActionsCard(isSuperAdmin: true),
                    SizedBox(height: 20.h),
                    const TopLoungesCard(),
                    SizedBox(height: 20.h),
                    const RecentActivityCard(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LoungeOwnerDashboardView extends StatelessWidget {
  const _LoungeOwnerDashboardView();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1200;

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShiftHeaderBanner(),
              SizedBox(height: 12.h),
              const DashboardHeader(isSuperAdmin: false),
              SizedBox(height: 20.h),
              const LoungeOwnerAnalyticsGrid(),
              SizedBox(height: 20.h),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          const RoomStatusCard(),
                          SizedBox(height: 20.h),
                          const LiveBookingsFeed(),
                          SizedBox(height: 20.h),
                          SizedBox(
                            height: 380.h,
                            child: ChartCard(
                              title: AppStrings.roomUtilization,
                              subtitle: AppStrings.capacityTracking,
                              actionIcon: Icons.pie_chart_outline,
                              actionIconColor: AppColors.neonPurple,
                              chart: const UtilizationChart(),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          const LoungeReviewsCard(),
                        ],
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          const QuickActionsCard(isSuperAdmin: false),
                          SizedBox(height: 20.h),
                          const RecentActivityCard(),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    const RoomStatusCard(),
                    SizedBox(height: 20.h),
                    const LiveBookingsFeed(),
                    SizedBox(height: 20.h),
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
                    SizedBox(height: 20.h),
                    const QuickActionsCard(isSuperAdmin: false),
                    SizedBox(height: 20.h),
                    const LoungeReviewsCard(),
                    SizedBox(height: 20.h),
                    const RecentActivityCard(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
