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
  String? _lastInitializedLoungeId;
  bool _isInitialized = false;

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

    if (_isInitialized && _lastInitializedLoungeId == cleanLoungeId) {
      return;
    }
    _isInitialized = true;
    _lastInitializedLoungeId = cleanLoungeId;

    if (widget.role != UserRole.superAdmin) {
      context.read<LoungeStatsCubit>().fetchStats(cleanLoungeId);
      context.read<DashboardCubit>().startWatchingActiveSessions(loungeId: cleanLoungeId);
      context.read<BookingCubit>().startWatchingBookings(loungeId: cleanLoungeId);
      if (cleanLoungeId != null) {
        context.read<RoomCubit>().watchRooms(cleanLoungeId);
        context.read<ClientRequestsCubit>().startWatchingRequests(loungeId: cleanLoungeId);
        context.read<ReviewsCubit>().startWatchingReviews(loungeId: cleanLoungeId);
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

class _ResponsiveDashboardLayout extends StatelessWidget {
  final List<Widget> mainChildren;
  final List<Widget> sideChildren;
  final List<Widget>? mobileChildren;

  const _ResponsiveDashboardLayout({
    required this.mainChildren,
    required this.sideChildren,
    this.mobileChildren,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1200;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: mainChildren,
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: sideChildren,
                ),
              ),
            ],
          );
        }

        final items = mobileChildren ?? [...mainChildren, ...sideChildren];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items,
        );
      },
    );
  }
}

class _SuperAdminDashboardView extends StatelessWidget {
  const _SuperAdminDashboardView();

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
          SliverPadding(
            padding: EdgeInsets.all(20.r),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                DashboardHeader(
                  isSuperAdmin: true,
                  onRefresh: () async {
                    await context.read<DashboardCubit>().loadDashboardData();
                  },
                ),
                SizedBox(height: 20.h),
                const RepaintBoundary(child: DashboardStatsGrid(isSuperAdmin: true)),
                SizedBox(height: 20.h),
                _ResponsiveDashboardLayout(
                  mainChildren: [
                    SizedBox(
                      height: 380.h,
                      child: ChartCard(
                        title: AppStrings.revenueAnalytics,
                        subtitle: AppStrings.weeklyPerformance,
                        actionIcon: Icons.trending_up,
                        actionIconColor: AppColors.success,
                        chart: const RepaintBoundary(child: RevenueChart()),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    const RepaintBoundary(child: TopLoungesCard()),
                  ],
                  sideChildren: [
                    const QuickActionsCard(isSuperAdmin: true),
                    SizedBox(height: 20.h),
                    const RepaintBoundary(child: RecentActivityCard()),
                  ],
                  mobileChildren: [
                    SizedBox(
                      height: 350.h,
                      child: ChartCard(
                        title: AppStrings.revenueAnalytics,
                        subtitle: AppStrings.weeklyPerformance,
                        actionIcon: Icons.trending_up,
                        actionIconColor: AppColors.success,
                        chart: const RepaintBoundary(child: RevenueChart()),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    const QuickActionsCard(isSuperAdmin: true),
                    SizedBox(height: 20.h),
                    const RepaintBoundary(child: TopLoungesCard()),
                    SizedBox(height: 20.h),
                    const RepaintBoundary(child: RecentActivityCard()),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoungeOwnerDashboardView extends StatelessWidget {
  const _LoungeOwnerDashboardView();

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
        context.read<ReviewsCubit>().startWatchingReviews(loungeId: cleanLoungeId, forceRefresh: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _handleRefresh(context),
      color: AppColors.neonBlue,
      backgroundColor: AppColors.cardBackground,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(20.r),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const ShiftHeaderBanner(),
                SizedBox(height: 12.h),
                DashboardHeader(
                  isSuperAdmin: false,
                  onRefresh: () => _handleRefresh(context),
                ),
                SizedBox(height: 20.h),
                const RepaintBoundary(child: LoungeOwnerAnalyticsGrid()),
                SizedBox(height: 20.h),
                _ResponsiveDashboardLayout(
                  mainChildren: [
                    const RepaintBoundary(child: RoomStatusCard()),
                    SizedBox(height: 20.h),
                    const RepaintBoundary(child: LiveBookingsFeed()),
                    SizedBox(height: 20.h),
                    SizedBox(
                      height: 380.h,
                      child: ChartCard(
                        title: AppStrings.roomUtilization,
                        subtitle: AppStrings.capacityTracking,
                        actionIcon: Icons.pie_chart_outline,
                        actionIconColor: AppColors.neonPurple,
                        chart: const RepaintBoundary(child: UtilizationChart()),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    const RepaintBoundary(child: LoungeReviewsCard()),
                  ],
                  sideChildren: [
                    const QuickActionsCard(isSuperAdmin: false),
                    SizedBox(height: 20.h),
                    const RepaintBoundary(child: RecentActivityCard()),
                  ],
                  mobileChildren: [
                    const QuickActionsCard(isSuperAdmin: false),
                    SizedBox(height: 20.h),
                    const RepaintBoundary(child: RoomStatusCard()),
                    SizedBox(height: 20.h),
                    const RepaintBoundary(child: LiveBookingsFeed()),
                    SizedBox(height: 20.h),
                    SizedBox(
                      height: 350.h,
                      child: ChartCard(
                        title: AppStrings.roomUtilization,
                        subtitle: AppStrings.capacityTracking,
                        actionIcon: Icons.pie_chart_outline,
                        actionIconColor: AppColors.neonPurple,
                        chart: const RepaintBoundary(child: UtilizationChart()),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    const RepaintBoundary(child: LoungeReviewsCard()),
                    SizedBox(height: 20.h),
                    const RepaintBoundary(child: RecentActivityCard()),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
