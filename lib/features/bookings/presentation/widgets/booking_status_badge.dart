import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

/// Standardized, reusable status badge for bookings across cards, headers, tables, and dialogs.
class BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;
  final bool isCancelledByClient;

  const BookingStatusBadge({
    super.key,
    required this.status,
    this.isCancelledByClient = false,
  });

  factory BookingStatusBadge.fromBooking(Booking booking, {Key? key}) {
    return BookingStatusBadge(
      key: key,
      status: booking.status,
      isCancelledByClient: booking.isCancelledByClient,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isCancelledByClient) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.6)),
        ),
        child: Text(
          AppStrings.cancelledByClientAfterApproval.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.danger,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    switch (status) {
      case BookingStatus.pendingVerification:
        return StatusBadge.warning(
          AppStrings.pendingVerification.toUpperCase(),
        );
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
}
