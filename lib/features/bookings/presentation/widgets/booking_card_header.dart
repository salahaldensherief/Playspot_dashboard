import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

class BookingCardHeader extends StatelessWidget {
  final Booking booking;
  final Color accent;
  final String shortId;

  const BookingCardHeader({
    super.key,
    required this.booking,
    required this.accent,
    required this.shortId,
  });

  Widget _getStatusBadge(Booking booking) {
    if (booking.isCancelledByClient) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          AppStrings.cancelledByClientAfterApproval,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    switch (booking.status) {
      case BookingStatus.pendingVerification:
        return StatusBadge.warning(AppStrings.pendingVerification.toUpperCase());
      case BookingStatus.pending:
        return StatusBadge.warning(AppStrings.pending.toUpperCase());
      case BookingStatus.upcoming:
        return StatusBadge.info(AppStrings.upcoming.toUpperCase());
      case BookingStatus.inProgress:
        return StatusBadge.success(AppStrings.inProgress.toUpperCase());
      case BookingStatus.completed:
        return StatusBadge.success(AppStrings.completed.toUpperCase());
      case BookingStatus.cancelled:
        return StatusBadge.danger(AppStrings.cancelled.toUpperCase());
      case BookingStatus.rejected:
        return StatusBadge.danger(AppStrings.requestRejected.toUpperCase());
    }
  }

  Widget _getPaymentTypeBadge(Booking booking) {
    if (booking.isCashPayment) {
      return StatusBadge.warning(AppStrings.cashBookingBadge);
    }
    return StatusBadge.info('${AppStrings.walletLabel} (${booking.displayWalletInfo})');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.08),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _getStatusBadge(booking),
                _getPaymentTypeBadge(booking),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          AppText.body(
            '#$shortId',
            fontSize: 10.5.sp,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
