import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/live_indicator_badge.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';

class BookingsCockpitStatsBar extends StatelessWidget {
  final String loungeId;
  final dynamic userLounge;
  final VoidCallback onNewBooking;

  const BookingsCockpitStatsBar({
    super.key,
    required this.loungeId,
    required this.userLounge,
    required this.onNewBooking,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      buildWhen: (prev, curr) =>
          prev.bookings != curr.bookings || prev.status != curr.status,
      builder: (context, bookingState) {
        return BlocBuilder<ShiftCubit, ShiftState>(
          buildWhen: (prev, curr) => prev.activeShift != curr.activeShift,
          builder: (context, shiftState) {
            final activeShift = shiftState.activeShift;
            final activeCount = bookingState.activeBookings.length;
            final pendingCount = bookingState.pendingBookings.length;
            final totalRevenue = bookingState.currentShiftRevenue(
              activeShift: activeShift,
              userLounge: userLounge,
            );
            final isSmallScreen = MediaQuery.sizeOf(context).width < 900;

            if (isSmallScreen) {
              return Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const LiveIndicatorBadge(),
                        AppButton(
                          text: AppStrings.newBooking,
                          icon: Icons.add_rounded,
                          variant: AppButtonVariant.primary,
                          height: 38.h,
                          onPressed: onNewBooking,
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCompactMetricCard(
                            'الجلسات الجارية',
                            '$activeCount',
                            AppColors.neonBlue,
                            Icons.sports_esports_rounded,
                          ),
                          SizedBox(width: 8.w),
                          _buildCompactMetricCard(
                            'طلبات بالانتظار',
                            '$pendingCount',
                            AppColors.warning,
                            Icons.access_time_filled_rounded,
                          ),
                          SizedBox(width: 8.w),
                          _buildCompactMetricCard(
                            'إيراد الوردية',
                            '${totalRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
                            AppColors.neonGreen,
                            Icons.account_balance_wallet_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cardBackground,
                    AppColors.cardBackground.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderDefault),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonBlue.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const LiveIndicatorBadge(),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Row(
                      children: [
                        _buildModernMetricCard(
                          'الجلسات الجارية',
                          '$activeCount',
                          AppColors.neonBlue,
                          Icons.sports_esports_rounded,
                        ),
                        SizedBox(width: 12.w),
                        _buildModernMetricCard(
                          'طلبات بالانتظار',
                          '$pendingCount',
                          AppColors.warning,
                          Icons.access_time_filled_rounded,
                        ),
                        SizedBox(width: 12.w),
                        _buildModernMetricCard(
                          'إيراد الوردية',
                          '${totalRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
                          AppColors.neonGreen,
                          Icons.account_balance_wallet_rounded,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 14.w),
                  AppButton(
                    text: AppStrings.newBooking,
                    icon: Icons.add_rounded,
                    variant: AppButtonVariant.primary,
                    height: 42.h,
                    onPressed: onNewBooking,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactMetricCard(
    String title,
    String value,
    Color accentColor,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.r, color: accentColor),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.sp,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernMetricCard(
    String title,
    String value,
    Color accentColor,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 16.r, color: accentColor),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                    ),
                    maxLines: 1,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    value,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
