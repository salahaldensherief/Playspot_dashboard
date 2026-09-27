import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';

class LiveBookingItem extends StatelessWidget {
  final Booking booking;

  const LiveBookingItem({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusStr = booking.status.toDbString();

    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: AppColors.neonBlue.withValues(alpha: 0.1),
          child: Icon(Icons.person_outline, color: AppColors.neonBlue, size: 20.r),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.subHeading(booking.userName ?? 'User ${booking.userId.substring(0, 5)}', fontSize: 14.sp),
              AppText.body('${booking.roomName} • ${booking.startTime}', fontSize: 12.sp),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _getStatusColor(statusStr).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: AppText.body(
            statusStr.toUpperCase(), 
            color: _getStatusColor(statusStr), 
            fontSize: 10.sp, 
            fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(width: 16.w),
        _buildAction(context),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'upcoming': return AppColors.neonBlue;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.danger;
      default: return AppColors.neonBlue;
    }
  }

  Widget _buildAction(BuildContext context) {
    if (booking.status == BookingStatus.pending) {
      return AppButton(
        text: AppStrings.approve,
        onPressed: () => context.read<BookingCubit>().approveBooking(booking.id),
        variant: AppButtonVariant.primary,
      );
    }
    
    if (booking.status == BookingStatus.upcoming && booking.paymentStatus == PaymentStatus.unpaid) {
      return AppButton(
        text: AppStrings.confirmCash,
        onPressed: () => context.read<BookingCubit>().confirmCashPayment(booking.id),
        variant: AppButtonVariant.primary,
      );
    }

    return const SizedBox.shrink();
  }
}
