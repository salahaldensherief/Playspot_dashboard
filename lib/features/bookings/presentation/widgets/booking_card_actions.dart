import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/services/booking_schedule.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_time_builder.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/start_session_button.dart';
import 'manual_payment_verification_dialog.dart';

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

  Future<void> _showNoShowConfirmDialog(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.confirmNoShow,
      message: AppStrings.confirmNoShowMessage,
      confirmText: AppStrings.markNoShow,
      confirmColor: AppColors.danger,
    );
    if (confirmed == true && context.mounted) {
      final cubit = context.read<BookingCubit>();
      final success = await cubit.markNoShow(booking.id);
      if (success && onNoShow != null) {
        onNoShow!();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? AppStrings.noShowSuccess : AppStrings.noShowFailed,
            ),
            backgroundColor: success ? AppColors.success : AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final double h = 36.h;

    Widget detailsButton() => AppButton(
      text: AppStrings.bookingDetails,
      variant: AppButtonVariant.outlined,
      onPressed: onOpenDetails,
      width: double.infinity,
      height: h,
    );

    // 0. Pending Verification (Manual Payment Queue)
    if (booking.status == BookingStatus.pendingVerification) {
      return AppButton(
        text: AppStrings.pendingVerification,
        variant: AppButtonVariant.primary,
        backgroundColor: AppColors.warning,
        icon: Icons.verified_user_rounded,
        height: h,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => ManualPaymentVerificationDialog(booking: booking),
          );
        },
      );
    }

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
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                icon: Icons.receipt_long_rounded,
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
                foregroundColor: AppColors.danger,
                icon: Icons.cancel_outlined,
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

      // A pending cash booking can start when its time arrives. Starting it
      // records attendance; collection stays a separate action.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (booking.canStartSession) ...[
            StartSessionButton(
              bookingId: booking.id,
              bookingDate: booking.date,
              startTime: booking.startTime,
              onSuccess: onStartSession,
              height: h,
              width: double.infinity,
            ),
            SizedBox(height: 8.h),
          ],
          Row(
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
                  foregroundColor: AppColors.danger,
                  icon: Icons.cancel_outlined,
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
          ),
        ],
      );
    }

    // Unverified prepaid methods cannot start; cash can be settled after play.
    if (booking.status == BookingStatus.upcoming && !booking.canStartSession) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: AppButton(
              text: booking.isCashPayment
                  ? AppStrings.confirmCash
                  : AppStrings.confirmReceipt,
              variant: AppButtonVariant.primary,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              icon: booking.isCashPayment
                  ? Icons.payments_rounded
                  : Icons.receipt_long_rounded,
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
            flex: 2,
            child: AppButton(
              text: AppStrings.reject,
              variant: AppButtonVariant.outlined,
              foregroundColor: AppColors.danger,
              icon: Icons.cancel_outlined,
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

    if (booking.canStartSession) {
      return SessionTimeBuilder(
        builder: (context, now) {
          final isReady = BookingSchedule.canStart(booking.startDateTime, now);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (isReady) ...[
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
                  ],
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      text: AppStrings.markNoShowAction,
                      variant: AppButtonVariant.outlined,
                      foregroundColor: AppColors.warning,
                      icon: Icons.person_off_outlined,
                      height: h,
                      onPressed: () => _showNoShowConfirmDialog(context),
                    ),
                  ),
                ],
              ),
              if (!isPaid && booking.isCashPayment) ...[
                SizedBox(height: 8.h),
                AppButton(
                  text: AppStrings.confirmCash,
                  variant: AppButtonVariant.outlined,
                  icon: Icons.payments_rounded,
                  height: h,
                  onPressed: onConfirmPayment ?? onOpenDetails,
                ),
              ],
            ],
          );
        },
      );
    }

    return detailsButton();
  }
}
