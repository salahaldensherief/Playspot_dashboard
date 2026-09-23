import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/users/presentation/cubit/moderation_cubit.dart';
import 'package:play_spot_dashboard/features/users/presentation/widgets/report_user_ban_dialog.dart';

class BookingDetailsCustomerCard extends StatelessWidget {
  final Booking booking;

  const BookingDetailsCustomerCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: AppColors.neonBlue.withAlpha(30),
            child: Text(
              (booking.userName ?? 'C').substring(0, 1).toUpperCase(),
              style: TextStyle(
                  color: AppColors.neonBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.userName ?? AppStrings.anonymous,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                Text(
                  booking.userPhone ?? 'لا يوجد هاتف',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.report_problem_outlined,
                color: AppColors.danger, size: 20),
            tooltip: 'إبلاغ وطلب حظر العميل',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => BlocProvider(
                  create: (_) => sl<ModerationCubit>(),
                  child: ReportUserBanDialog(
                    loungeId: booking.loungeId,
                    userId: booking.userId,
                    bookingId: booking.id,
                    userName: booking.userName,
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: booking.isFirstBooking
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: booking.isFirstBooking
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : AppColors.borderDefault,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  booking.isFirstBooking ? Icons.star_rounded : Icons.person_pin_circle_outlined,
                  size: 14.r,
                  color: booking.isFirstBooking ? AppColors.warning : AppColors.neonPurple,
                ),
                SizedBox(width: 4.w),
                Text(
                  booking.isFirstBooking ? AppStrings.firstBookingBadge : AppStrings.returningCustomerBadge,
                  style: TextStyle(
                    color: booking.isFirstBooking ? AppColors.warning : AppColors.textPrimary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
