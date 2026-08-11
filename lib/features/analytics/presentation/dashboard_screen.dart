import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/room_status_card.dart';
import 'dashboard_cubit.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_stats_grid.dart';
import 'widgets/dashboard_charts_row.dart';
import 'widgets/recent_activities.dart';
import 'widgets/top_lounges_card.dart';
import 'widgets/live_bookings_feed.dart';

class DashboardScreen extends StatelessWidget {
  final UserRole role;
  
  const DashboardScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId;
    final isSuperAdmin = role == UserRole.superAdmin;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<BookingCubit>()..startWatchingBookings(loungeId: loungeId)),
        BlocProvider(create: (context) => sl<DashboardCubit>()..loadDashboardData(loungeId: loungeId)),
      ],
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(isSuperAdmin: isSuperAdmin),
            SizedBox(height: 32.h),
            DashboardStatsGrid(isSuperAdmin: isSuperAdmin),
            SizedBox(height: 32.h),
            const DashboardChartsRow(),
            SizedBox(height: 32.h),
            _DashboardBottomSection(isSuperAdmin: isSuperAdmin),
          ],
        ),
      ),
    );
  }
}

class _DashboardBottomSection extends StatelessWidget {
  final bool isSuperAdmin;
  const _DashboardBottomSection({required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              if (!isSuperAdmin) ...[
                const LiveBookingsFeed(),
                SizedBox(height: 24.h),
              ],
              if (isSuperAdmin) const TopLoungesCard(),
            ],
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const RecentActivityCard(),
              if (!isSuperAdmin) ...[
                SizedBox(height: 24.h),
                const RoomStatusCard(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
