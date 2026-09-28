import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/art_core/widgets/stat_card.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';
import '../lounge_stats_cubit.dart';
import '../lounge_stats_state.dart';

class CockpitKpiGrid extends StatelessWidget {
  final bool isSuperAdmin;
  final VoidCallback? onRetry;

  const CockpitKpiGrid({super.key, this.isSuperAdmin = false, this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (isSuperAdmin) {
      return _SuperAdminKpiGrid(onRetry: onRetry);
    }
    return _LoungeOwnerKpiGrid(onRetry: onRetry);
  }
}

class _SuperAdminKpiGrid extends StatelessWidget {
  final VoidCallback? onRetry;

  const _SuperAdminKpiGrid({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.totalRevenue != curr.totalRevenue ||
          prev.activeSessions != curr.activeSessions ||
          prev.occupancyRate != curr.occupancyRate ||
          prev.totalLounges != curr.totalLounges ||
          prev.bookingsToday != curr.bookingsToday ||
          prev.cancelledBookings != curr.cancelledBookings,
      builder: (context, state) {
        if (state.status == FeatureStatus.loading) {
          return const _KpiGridShimmer();
        }

        if (state.status == FeatureStatus.failure) {
          return _KpiErrorCard(
            message: state.errorMessage ?? AppStrings.failedToLoadStats,
            onRetry: onRetry,
          );
        }

        final crossAxisCount = context.responsive<int>(
          mobile: 2,
          tablet: 3,
          desktop: 6,
        );

        final extent = context.responsive<double>(
          mobile: 116.h,
          tablet: 124.h,
          desktop: 130.h,
        );

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          addSemanticIndexes: false,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14.w,
            mainAxisSpacing: 14.h,
            mainAxisExtent: extent,
          ),
          children: [
            StatCard(
              title: AppStrings.globalOverview,
              value: '\$${state.totalRevenue.toStringAsFixed(0)}',
              trendValue: state.revenueTrend,
              icon: Icons.payments_outlined,
              iconColor: AppColors.neonGreen,
            ),
            StatCard(
              title: AppStrings.loungeOccupancy,
              value: '${(state.occupancyRate * 100).toStringAsFixed(0)}%',
              trendValue: state.occupancyTrend,
              icon: Icons.meeting_room_outlined,
              iconColor: AppColors.neonPurple,
            ),
            StatCard(
              title: AppStrings.activeSessions,
              value: '${state.activeSessions}',
              trendValue: state.bookingsTrend,
              icon: Icons.sports_esports_outlined,
              iconColor: AppColors.neonBlue,
            ),
            StatCard(
              title: AppStrings.bookingsLabel,
              value: '${state.totalBookings}',
              subtitle: '${state.bookingsToday} ${AppStrings.today}',
              trendValue: state.bookingsTrend,
              icon: Icons.confirmation_number_outlined,
              iconColor: AppColors.neonCyan,
            ),
            StatCard(
              title: AppStrings.noShowsAndCancellations,
              value: '${state.cancelledBookings}',
              subtitle: AppStrings.systemHealth,
              trendValue: 0.0,
              icon: Icons.event_busy_outlined,
              iconColor: state.cancelledBookings > 0
                  ? AppColors.danger
                  : AppColors.textMuted,
            ),
            StatCard(
              title: AppStrings.payouts,
              value: '\$${state.totalPlatformCommission.toStringAsFixed(0)}',
              subtitle: AppStrings.payouts,
              trendValue: 0.0,
              icon: Icons.account_balance_wallet_outlined,
              iconColor: Colors.orangeAccent,
            ),
          ],
        );
      },
    );
  }
}

class _LoungeOwnerKpiGrid extends StatelessWidget {
  final VoidCallback? onRetry;

  const _LoungeOwnerKpiGrid({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoungeStatsCubit, LoungeStatsState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.stats != curr.stats,
      builder: (context, loungeStatsState) {
        return BlocBuilder<BookingCubit, BookingState>(
          buildWhen: (prev, curr) =>
              prev.status != curr.status || prev.bookings != curr.bookings,
          builder: (context, bookingState) {
            return BlocBuilder<DashboardCubit, DashboardState>(
              buildWhen: (prev, curr) =>
                  prev.activeSessions != curr.activeSessions ||
                  prev.totalRevenue != curr.totalRevenue ||
                  prev.activeSessionsList != curr.activeSessionsList,
              builder: (context, dashState) {
                if (loungeStatsState.status == LoungeStatsStatus.loading &&
                    loungeStatsState.stats == null) {
                  return const _KpiGridShimmer();
                }

                if (loungeStatsState.status == LoungeStatsStatus.failure &&
                    loungeStatsState.stats == null) {
                  return _KpiErrorCard(
                    message:
                        loungeStatsState.errorMessage ??
                        AppStrings.failedToLoadStats,
                    onRetry: onRetry,
                  );
                }

                final stats = loungeStatsState.stats;
                final bookings = bookingState.bookings;

                // Today revenue
                final double todayRevenue =
                    stats?.todayRevenue ?? dashState.totalRevenue;

                // Occupancy
                final double occupancyRate =
                    stats?.occupancyRate ?? dashState.occupancyRate;
                final int occupiedRooms = stats?.occupiedRooms ?? 0;
                final int totalRooms = stats?.totalRooms ?? 0;

                // Active sessions count
                final int activeCount = dashState.activeSessionsList.isNotEmpty
                    ? dashState.activeSessionsList
                          .where((b) => b.isBookingActive())
                          .length
                    : bookings.where((b) => b.isBookingActive()).length;

                // Pending payment proofs count
                final int pendingProofsCount = bookings.where((b) {
                  final hasReceipt =
                      b.receiptUrl != null && b.receiptUrl!.trim().isNotEmpty;
                  final isUnpaid = b.paymentStatus != PaymentStatus.paid;
                  final isPendingVerification =
                      b.status == BookingStatus.pendingVerification;
                  return (hasReceipt && isUnpaid) || isPendingVerification;
                }).length;

                // Cancellations & No-Shows count
                final int cancellationsCount = bookings.where((b) {
                  return b.status == BookingStatus.cancelled ||
                      (b.cancellationReason != null &&
                          b.cancellationReason!.trim().isNotEmpty);
                }).length;

                // Canteen revenue
                final double canteenRevenue = bookings.fold<double>(
                  0.0,
                  (sum, b) => sum + (b.addonsPrice ?? 0.0),
                );

                final crossAxisCount = context.responsive<int>(
                  mobile: 2,
                  tablet: 3,
                  desktop: 6,
                );

                final extent = context.responsive<double>(
                  mobile: 116.h,
                  tablet: 124.h,
                  desktop: 130.h,
                );

                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  addSemanticIndexes: false,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14.w,
                    mainAxisSpacing: 14.h,
                    mainAxisExtent: extent,
                  ),
                  children: [
                    // 1. Today Revenue
                    StatCard(
                      title: AppStrings.dailyRevenue,
                      value:
                          '${todayRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
                      subtitle: AppStrings.dailyTotal,
                      trendValue: 0.0,
                      icon: Icons.payments_outlined,
                      iconColor: AppColors.neonGreen,
                    ),

                    // 2. Room Occupancy
                    StatCard(
                      title: AppStrings.loungeOccupancy,
                      value: '${(occupancyRate * 100).toStringAsFixed(0)}%',
                      subtitle: totalRooms > 0
                          ? AppStrings.occupiedRoomsSubtitle(
                              occupiedRooms,
                              totalRooms,
                            )
                          : AppStrings.rooms,
                      trendValue: 0.0,
                      icon: Icons.meeting_room_outlined,
                      iconColor: AppColors.neonPurple,
                    ),

                    // 3. Active Bookings / Sessions
                    StatCard(
                      title: AppStrings.activeSessions,
                      value: '$activeCount',
                      subtitle: AppStrings.openSessionsCount(activeCount),
                      trendValue: 0.0,
                      icon: Icons.sports_esports_outlined,
                      iconColor: AppColors.neonBlue,
                    ),

                    // 4. Pending Payment Proofs
                    StatCard(
                      title: AppStrings.pendingPaymentProofs,
                      value: '$pendingProofsCount',
                      subtitle: pendingProofsCount > 0
                          ? AppStrings.pendingRequests
                          : AppStrings.systemHealth,
                      trendValue: 0.0,
                      icon: Icons.receipt_long_outlined,
                      iconColor: pendingProofsCount > 0
                          ? AppColors.warning
                          : AppColors.textMuted,
                    ),

                    // 5. No-Shows / Cancellations
                    StatCard(
                      title: AppStrings.noShowsAndCancellations,
                      value: '$cancellationsCount',
                      subtitle: cancellationsCount > 0
                          ? AppStrings.cancelled
                          : AppStrings.systemHealth,
                      trendValue: 0.0,
                      icon: Icons.event_busy_outlined,
                      iconColor: cancellationsCount > 0
                          ? AppColors.danger
                          : AppColors.textMuted,
                    ),

                    // 6. Canteen Revenue
                    StatCard(
                      title: AppStrings.canteenRevenue,
                      value:
                          '${canteenRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
                      subtitle: AppStrings.extras,
                      trendValue: 0.0,
                      icon: Icons.fastfood_outlined,
                      iconColor: AppColors.neonCyan,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _KpiGridShimmer extends StatelessWidget {
  const _KpiGridShimmer();

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = context.responsive<int>(
      mobile: 2,
      tablet: 3,
      desktop: 6,
    );

    final extent = context.responsive<double>(
      mobile: 116.h,
      tablet: 124.h,
      desktop: 130.h,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      addSemanticIndexes: false,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14.w,
        mainAxisSpacing: 14.h,
        mainAxisExtent: extent,
      ),
      itemCount: 6,
      itemBuilder: (context, index) =>
          ShimmerLoading.rounded(height: extent, width: double.infinity),
    );
  }
}

class _KpiErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _KpiErrorCard({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 28.r,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(width: 12.w),
            AppButton(
              text: AppStrings.retry,
              icon: Icons.refresh,
              variant: AppButtonVariant.outlined,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
