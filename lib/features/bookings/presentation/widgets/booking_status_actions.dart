import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import '../../domain/entities/booking.dart';

/// Reusable UI Widget containing action buttons for updating booking status,
/// confirming cash payments, and swapping rooms.
class BookingStatusActions extends StatelessWidget {
  final Booking booking;
  final bool isLoading;
  final VoidCallback? onApprove;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final VoidCallback? onConfirmPayment;
  final VoidCallback? onSwapRoom;

  const BookingStatusActions({
    super.key,
    required this.booking,
    this.isLoading = false,
    this.onApprove,
    this.onCancel,
    this.onComplete,
    this.onConfirmPayment,
    this.onSwapRoom,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == BookingStatus.pending;
    final isUpcoming = booking.status == BookingStatus.upcoming;
    final isInProgress = booking.status == BookingStatus.inProgress;
    final isCompleted = booking.status == BookingStatus.completed;
    final isCancelled = booking.status == BookingStatus.cancelled;
    final isUnpaid = booking.paymentStatus != PaymentStatus.paid;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(color: AppColors.neonBlue),
        ),
      );
    }

    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Swap Room Action
        if ((isInProgress || isUpcoming) && onSwapRoom != null)
          AppButton(
            text: AppStrings.swapRoom,
            variant: AppButtonVariant.outlined,
            onPressed: onSwapRoom,
          ),

        // Approve Action (for Pending bookings)
        if (isPending && onApprove != null)
          AppButton(
            text: AppStrings.approve,
            variant: AppButtonVariant.primary,
            onPressed: onApprove,
          ),

        // Complete Action (for InProgress / Upcoming bookings)
        if ((isInProgress || isUpcoming) && onComplete != null)
          AppButton(
            text: AppStrings.completeBooking,
            variant: AppButtonVariant.primary,
            onPressed: onComplete,
          ),

        // Cancel / Reject Action
        if (!isCompleted && !isCancelled && onCancel != null)
          AppButton(
            text: AppStrings.cancelBooking,
            variant: AppButtonVariant.outlined,
            onPressed: onCancel,
          ),

        // Confirm Cash Payment Action
        if (isUnpaid && !isCancelled && onConfirmPayment != null)
          AppButton(
            text: AppStrings.confirmCash,
            variant: AppButtonVariant.primary,
            onPressed: onConfirmPayment,
          ),
      ],
    );
  }
}
