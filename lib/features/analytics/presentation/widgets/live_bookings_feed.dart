import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
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
                      Text(
                        AppStrings.liveBookingsFeed,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
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
                    return _LiveBookingItem(
                      customerName: 'User ${booking.userId.substring(0, 5)}',
                      roomName: 'Room ${booking.roomId.substring(0, 3)}',
                      startTime: '14:30',
                      status: booking.status.name,
                      onConfirm: () => context.read<BookingCubit>().confirmCashPayment(booking.id),
                    );
                  },
                )
              else if (state is BookingError)
                Text('Error loading live feed: ${state.message}', style: const TextStyle(color: AppColors.danger))
              else
                const Text('Waiting for live updates...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        );
      },
    );
  }
}

class _LiveBookingItem extends StatelessWidget {
  final String customerName;
  final String roomName;
  final String startTime;
  final String status;
  final VoidCallback onConfirm;

  const _LiveBookingItem({
    required this.customerName,
    required this.roomName,
    required this.startTime,
    required this.status,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(customerName, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp)),
              Text('$roomName • $startTime', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.neonBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(status.toUpperCase(), style: TextStyle(color: AppColors.neonBlue, fontSize: 10.sp, fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 16.w),
        AppButton(
          text: 'Confirm Cash',
          onPressed: onConfirm,
          variant: AppButtonVariant.primary,
        ),
      ],
    );
  }
}
