import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'live_booking_item.dart';

class LiveBookingsFeed extends StatelessWidget {
  const LiveBookingsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(20.r),
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
                  if (state.status == BookingStatusState.loading && state.bookings.isEmpty) 
                    SizedBox(width: 16.r, height: 16.r, child: const CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              SizedBox(height: 20.h),
              if (state.status == BookingStatusState.success || state.bookings.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.bookings.take(5).length,
                  separatorBuilder: (_, __) => Divider(color: AppColors.divider, height: 32.h),
                  itemBuilder: (context, index) {
                    final booking = state.bookings[index];
                    return LiveBookingItem(booking: booking);
                  },
                )
              else if (state.status == BookingStatusState.failure)
                AppText.body('Error: ${state.errorMessage}', color: AppColors.danger)
              else
                AppText.body('Waiting for live updates...', color: AppColors.textSecondary),
            ],
          ),
        );
      },
    );
  }
}
