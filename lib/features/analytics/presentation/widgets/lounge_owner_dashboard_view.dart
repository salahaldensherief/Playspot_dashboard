import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import '../dashboard_cubit.dart';
import '../lounge_stats_cubit.dart';
import 'dashboard_header.dart';
import 'dashboard_time_range_selector.dart';
import 'desktop_lounge_dashboard_content.dart';
import 'mobile_lounge_dashboard_content.dart';
import 'tablet_lounge_dashboard_content.dart';

class LoungeOwnerDashboardView extends StatelessWidget {
  final DashboardTimeRange timeRange;
  final ValueChanged<DashboardTimeRange> onTimeRangeChanged;

  const LoungeOwnerDashboardView({
    super.key,
    required this.timeRange,
    required this.onTimeRangeChanged,
  });

  Future<void> _handleRefresh(BuildContext context) async {
    final loungeId = context.read<LoginCubit>().state.user?.loungeId;
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty)
        ? loungeId.trim()
        : null;

    await context.read<LoungeStatsCubit>().fetchStats(cleanLoungeId);
    if (context.mounted) {
      context.read<DashboardCubit>().startWatchingActiveSessions(
        loungeId: cleanLoungeId,
        forceRefresh: true,
      );
      context.read<BookingCubit>().startWatchingBookings(
        loungeId: cleanLoungeId,
        forceRefresh: true,
      );
      if (cleanLoungeId != null) {
        context.read<RoomCubit>().watchRooms(cleanLoungeId, forceRefresh: true);
        context.read<ClientRequestsCubit>().startWatchingRequests(
          loungeId: cleanLoungeId,
          forceRefresh: true,
        );
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
          SliverToBoxAdapter(child: _buildHeaderSection(context)),
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          SliverToBoxAdapter(
            child: Responsive(
              mobile: MobileLoungeDashboardContent(
                onRefresh: () => _handleRefresh(context),
              ),
              tablet: TabletLoungeDashboardContent(
                onRefresh: () => _handleRefresh(context),
              ),
              desktop: DesktopLoungeDashboardContent(
                onRefresh: () => _handleRefresh(context),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Row(
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
    );
  }
}
