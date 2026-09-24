import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/start_session_button.dart';

class BookingCardActions extends StatelessWidget {
  final Booking booking;
  final bool isPaid;
  final bool isPending;
  final bool isCanStartSession;
  final VoidCallback onOpenDetails;
  final VoidCallback? onApprove;
  final VoidCallback? onStartSession;
  final VoidCallback? onConfirmPayment;
  final VoidCallback? onReject;
  final VoidCallback? onNoShow;

  const BookingCardActions({
    super.key,
    required this.booking,
    required this.isPaid,
    required this.isPending,
    required this.isCanStartSession,
    required this.onOpenDetails,
    this.onApprove,
    this.onStartSession,
    this.onConfirmPayment,
    this.onReject,
    this.onNoShow,
  });

  void _showNoShowConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Row(
          children: [
            const Icon(Icons.person_off, color: AppColors.danger),
            SizedBox(width: 8.w),
            Expanded(
              child: AppText.subHeading(
                AppStrings.confirmNoShow,
                color: AppColors.danger,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
        content: AppText.body(
          AppStrings.confirmNoShowMessage,
          fontSize: 12.sp,
          color: AppColors.textPrimary,
        ),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          AppButton(
            text: AppStrings.markNoShow,
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final cubit = context.read<BookingCubit>();
              final success = await cubit.markNoShow(booking.id);
              if (onNoShow != null) {
                onNoShow!();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? AppStrings.noShowSuccess : AppStrings.noShowFailed),
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double h = 36.h;

    Widget detailsButton() => AppButton(
          text: AppStrings.bookingDetails,
          variant: AppButtonVariant.outlined,
          onPressed: onOpenDetails,
          width: double.infinity,
          height: h,
        );

    // 1. Pending Bookings (MUST be approved or rejected first)
    if (isPending || booking.status == BookingStatus.pending) {
      if (!isPaid && !booking.isCashPayment) {
        // Electronic payment waiting for confirmation
        return Row(
          children: [
            Expanded(
              child: AppButton(
                text: AppStrings.confirmReceipt,
                variant: AppButtonVariant.primary,
                backgroundColor: AppColors.neonBlue,
                height: h,
                onPressed: () {
                  if (onConfirmPayment != null) {
                    onConfirmPayment!();
                  } else {
                    onOpenDetails();
                  }
                },
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: AppButton(
                text: AppStrings.reject,
                variant: AppButtonVariant.outlined,
                height: h,
                onPressed: () {
                  if (onReject != null) {
                    onReject!();
                  } else {
                    context.read<BookingCubit>().rejectBooking(booking.id);
                  }
                },
              ),
            ),
          ],
        );
      }

      // Cash or standard pending booking
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: AppButton(
              text: AppStrings.confirmBooking,
              variant: AppButtonVariant.primary,
              backgroundColor: AppColors.success,
              icon: Icons.check_circle_outline_rounded,
              height: h,
              onPressed: () {
                if (onApprove != null) {
                  onApprove!();
                } else {
                  context.read<BookingCubit>().approveBooking(booking.id);
                }
              },
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: AppButton(
              text: AppStrings.reject,
              variant: AppButtonVariant.outlined,
              height: h,
              onPressed: () {
                if (onReject != null) {
                  onReject!();
                } else {
                  context.read<BookingCubit>().rejectBooking(booking.id);
                }
              },
            ),
          ),
        ],
      );
    }

    // 2. Approved upcoming booking (Ready to start when time is reached)
    if (booking.status == BookingStatus.upcoming) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: StartSessionButton(
              bookingId: booking.id,
              bookingDate: booking.date,
              startTime: booking.startTime,
              onSuccess: onStartSession,
              height: h,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: AppButton(
              text: AppStrings.markNoShowAction,
              variant: AppButtonVariant.outlined,
              height: h,
              onPressed: () => _showNoShowConfirmDialog(context),
            ),
          ),
        ],
      );
    }

    return detailsButton();
  }
}
