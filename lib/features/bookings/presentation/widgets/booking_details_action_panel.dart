import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'swap_room_dialog.dart';

class BookingDetailsActionPanel extends StatelessWidget {
  final Booking booking;
  final bool isLoading;
  final VoidCallback onConfirmCashPayment;

  const BookingDetailsActionPanel({
    super.key,
    required this.booking,
    required this.isLoading,
    required this.onConfirmCashPayment,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingCubit>();
    final isPending = booking.status == BookingStatus.pending;
    final isInProgress = booking.status == BookingStatus.inProgress;
    final isUpcoming = booking.status == BookingStatus.upcoming;
    final isUnpaid = booking.paymentStatus != PaymentStatus.paid;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(color: AppColors.neonBlue),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPending)
          AppButton(
            text: 'قبول الحجز الآن',
            variant: AppButtonVariant.primary,
            backgroundColor: AppColors.success,
            height: 40.h,
            onPressed: () => cubit.approveBooking(booking.id),
          ),
        if (isUpcoming || isInProgress)
          AppButton(
            text: isInProgress ? 'إنهاء وحساب الجلسة' : 'بدء الجلسة الآن',
            variant: AppButtonVariant.primary,
            height: 40.h,
            onPressed: () {
              if (isInProgress) {
                cubit.changeBookingStatus(booking.id, BookingStatus.completed);
                Navigator.pop(context);
              } else if (isUpcoming) {
                cubit.startBookingSession(booking.id);
                Navigator.pop(context);
              }
            },
          ),
        if (isUnpaid && !isPending) ...[
          SizedBox(height: 8.h),
          AppButton(
            text: AppStrings.confirmCash,
            variant: AppButtonVariant.primary,
            backgroundColor: AppColors.neonBlue,
            height: 40.h,
            onPressed: onConfirmCashPayment,
          ),
        ],
        SizedBox(height: 8.h),
        Row(
          children: [
            if (isInProgress || isUpcoming)
              Expanded(
                child: AppButton(
                  text: AppStrings.swapRoom,
                  variant: AppButtonVariant.outlined,
                  height: 36.h,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => SwapRoomDialog(
                        bookingId: booking.id,
                        currentRoomId: booking.roomId,
                      ),
                    );
                  },
                ),
              ),
            if (isInProgress || isUpcoming) SizedBox(width: 8.w),
            if (booking.status != BookingStatus.cancelled &&
                booking.status != BookingStatus.completed)
              Expanded(
                child: AppButton(
                  text: AppStrings.cancelBooking,
                  variant: AppButtonVariant.danger,
                  height: 36.h,
                  onPressed: () {
                    cubit.rejectBooking(booking.id);
                    Navigator.pop(context);
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}
