import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../../bookings/presentation/cubit/booking_cubit.dart';
import '../../../bookings/presentation/cubit/booking_state.dart';
import '../../../bookings/presentation/widgets/live_session_card.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';
import 'live_booking_item.dart';

/// Refactored, high-performance Live Operations Feed displaying active gaming sessions,
/// real-time revenue stats, and incoming booking requests.
class LiveBookingsFeed extends StatelessWidget {
  const LiveBookingsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.activeSessionsList != curr.activeSessionsList ||
          prev.activeSessionsStats != curr.activeSessionsStats,
      builder: (context, dashState) {
        return BlocBuilder<BookingCubit, BookingState>(
          buildWhen: (prev, curr) => prev.status != curr.status || prev.bookings != curr.bookings,
          builder: (context, bookingState) {
            final List<Booking> activeSessions = dashState.activeSessionsList.isNotEmpty
                ? dashState.activeSessionsList.where((b) => b.isBookingActive()).toList()
                : bookingState.bookings.where((b) => b.isBookingActive()).toList();

            final stats = dashState.activeSessionsStats;
            final double activeRevenue = (stats['total_revenue'] as num?)?.toDouble() ??
                activeSessions.fold(0.0, (sum, item) => sum + item.totalPrice);
            final int activeExtrasCount = (stats['total_extras_count'] as num?)?.toInt() ??
                activeSessions.fold(0, (sum, item) => sum + item.extras.length);

            return Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LiveFeedHeader(
                    activeCount: activeSessions.length,
                    isLoading: dashState.status == FeatureStatus.loading && activeSessions.isEmpty,
                  ),
                  SizedBox(height: 16.h),

                  if (activeSessions.isNotEmpty) ...[
                    _ActiveSessionsStatsBar(
                      activeCount: activeSessions.length,
                      totalRevenue: activeRevenue,
                      extrasCount: activeExtrasCount,
                    ),
                    SizedBox(height: 20.h),
                    Wrap(
                      spacing: 16.r,
                      runSpacing: 16.r,
                      children: activeSessions.map((session) {
                        return RepaintBoundary(
                          child: LiveSessionCard(
                            key: ValueKey('dash_live_${session.id}'),
                            booking: session,
                            width: 320.w,
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const _EmptyActiveSessionsState(),
                  ],

                  if (bookingState.bookings.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Divider(color: AppColors.divider),
                    SizedBox(height: 12.h),
                    AppText.subHeading(
                      AppStrings.liveBookingsFeed,
                      fontSize: 15.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 12.h),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bookingState.bookings.take(5).length,
                      separatorBuilder: (context, index) => Divider(color: AppColors.divider, height: 20.h),
                      itemBuilder: (context, index) {
                        final booking = bookingState.bookings[index];
                        return LiveBookingItem(booking: booking);
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LiveFeedHeader extends StatelessWidget {
  final int activeCount;
  final bool isLoading;

  const _LiveFeedHeader({required this.activeCount, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12.r,
              height: 12.r,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            AppText.heading(
              AppStrings.activeSessions,
              fontSize: 18.sp,
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppText.body(
                '$activeCount',
                color: AppColors.neonBlue,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (isLoading)
          SizedBox(width: 16.r, height: 16.r, child: const CircularProgressIndicator(strokeWidth: 2)),
      ],
    );
  }
}

class _ActiveSessionsStatsBar extends StatelessWidget {
  final int activeCount;
  final double totalRevenue;
  final int extrasCount;

  const _ActiveSessionsStatsBar({
    required this.activeCount,
    required this.totalRevenue,
    required this.extrasCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStatTile(
              title: AppStrings.activeSessions,
              value: '$activeCount',
              icon: Icons.sports_esports,
              color: AppColors.neonBlue,
            ),
          ),
          Container(width: 1.w, height: 28.h, color: AppColors.divider),
          Expanded(
            child: _MiniStatTile(
              title: AppStrings.activeSessionRevenue,
              value: '${totalRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
              icon: Icons.account_balance_wallet,
              color: AppColors.neonGreen,
            ),
          ),
          Container(width: 1.w, height: 28.h, color: AppColors.divider),
          Expanded(
            child: _MiniStatTile(
              title: AppStrings.totalActiveExtras,
              value: '$extrasCount',
              icon: Icons.restaurant,
              color: AppColors.neonCyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18.r, color: color),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(title, fontSize: 10.sp, color: AppColors.textMuted),
            AppText.subHeading(value, fontSize: 13.sp, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ],
        ),
      ],
    );
  }
}

class _EmptyActiveSessionsState extends StatelessWidget {
  const _EmptyActiveSessionsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.sports_esports_outlined, size: 40.r, color: AppColors.textMuted),
            SizedBox(height: 8.h),
            AppText.body(
              AppStrings.noActiveSessions,
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
          ],
        ),
      ),
    );
  }
}
