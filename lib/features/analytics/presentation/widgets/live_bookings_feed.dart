import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';

class LiveBookingsFeed extends StatelessWidget {
  const LiveBookingsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        AppStrings.liveBookingsFeed,
                        fontSize: 18.sp,
                      ),
                    ],
                  ),
                  if (state is BookingLoading) 
                    SizedBox(width: 16.r, height: 16.r, child: const CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              SizedBox(height: 20.h),
              if (state is BookingLoaded)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.bookings.take(5).length,
                  separatorBuilder: (_, __) => Divider(color: AppColors.divider, height: 32.h),
                  itemBuilder: (context, index) {
                    final booking = state.bookings[index];
                    return _LiveBookingItem(booking: booking);
                  },
                )
              else if (state is BookingError)
                AppText.body('Error: ${state.message}', color: AppColors.danger)
              else
                AppText.body('Waiting for live updates...', color: AppColors.textSecondary),
            ],
          ),
        );
      },
    );
  }
}

class _LiveBookingItem extends StatelessWidget {
  final Booking booking;

  const _LiveBookingItem({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusStr = booking.status.toString().split('.').last;

    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: AppColors.neonBlue.withOpacity(0.1),
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
            color: _getStatusColor(statusStr).withOpacity(0.1),
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
    
    if (booking.status == BookingStatus.upcoming && booking.paymentStatus != 'paid') {
      return AppButton(
        text: AppStrings.confirmCash,
        onPressed: () => context.read<BookingCubit>().confirmCashPayment(booking.id),
        variant: AppButtonVariant.primary,
      );
    }

    return const SizedBox.shrink();
  }
}
