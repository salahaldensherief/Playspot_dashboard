import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_details_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/extend_session_dialog.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_requests_badge.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';

class RoomOccupancyActiveSection extends StatefulWidget {
  final Booking activeBooking;
  final RoomEntity room;
  final Duration remaining;
  final bool isExpired;
  final String formattedRemaining;

  const RoomOccupancyActiveSection({
    super.key,
    required this.activeBooking,
    required this.room,
    required this.remaining,
    required this.isExpired,
    required this.formattedRemaining,
  });

  @override
  State<RoomOccupancyActiveSection> createState() => _RoomOccupancyActiveSectionState();
}

class _RoomOccupancyActiveSectionState extends State<RoomOccupancyActiveSection> {
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final activeBooking = widget.activeBooking;
    final room = widget.room;
    final isExpired = widget.isExpired;
    final formattedRemaining = widget.formattedRemaining;
    final phone = activeBooking.userPhone;
    final isOpenTime = activeBooking.isOpenEnded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer Info Box
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.mutedBackground.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10.r),
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
                      Icon(Icons.person, color: AppColors.neonBlue, size: 14.r),
                      SizedBox(width: 6.w),
                      AppText.subHeading(
                        activeBooking.userName ?? AppStrings.anonymous,
                        fontSize: 13.sp,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: AppText.body(
                      '${activeBooking.totalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                      fontSize: 11.sp,
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (phone != null && phone.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.phone, color: AppColors.neonBlue, size: 12.r),
                    SizedBox(width: 6.w),
                    AppText.body(
                      phone,
                      fontSize: 11.sp,
                      color: AppColors.neonBlue,
                    ),
                    SizedBox(width: 6.w),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: phone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.phoneCopied),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Icon(Icons.copy_rounded, size: 12.r, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // Remaining Time Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isExpired
                ? AppColors.danger.withValues(alpha: 0.15)
                : AppColors.neonBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isExpired ? AppColors.danger : AppColors.neonBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isOpenTime
                        ? Icons.all_inclusive_rounded
                        : (isExpired ? Icons.timer_off : Icons.timer),
                    size: 16.r,
                    color: isExpired ? AppColors.danger : AppColors.neonBlue,
                  ),
                  SizedBox(width: 6.w),
                  AppText.body(
                    isOpenTime
                        ? AppStrings.duration
                        : (isExpired ? AppStrings.timeExpired : AppStrings.remainingTime),
                    fontSize: 11.sp,
                    color: isExpired ? AppColors.danger : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              AppText.subHeading(
                isOpenTime
                    ? formattedRemaining
                    : (isExpired ? '-$formattedRemaining' : formattedRemaining),
                fontSize: 14.sp,
                color: isExpired ? AppColors.danger : AppColors.neonBlue,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
        RoomOccupancyRequestsBadge(booking: activeBooking, room: room),
        SizedBox(height: 10.h),

        // Action Buttons: Details & Extend
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: AppStrings.bookingAndClientDetails,
                icon: Icons.info_outline_rounded,
                variant: AppButtonVariant.outlined,
                height: 32.h,
                onPressed: () {
                  showDialog(
                    context: context,
                    useRootNavigator: false,
                    builder: (_) => BookingDetailsDialog(booking: activeBooking),
                  );
                },
              ),
            ),
            SizedBox(width: 8.w),
            AppButton(
              text: isOpenTime ? AppStrings.completeAndCalculate : AppStrings.extendTime,
              icon: isOpenTime
                  ? Icons.price_check_rounded
                  : Icons.add_alarm_rounded,
              variant: AppButtonVariant.primary,
              height: 32.h,
              isLoading: isOpenTime && _isCompleting,
              onPressed: (isOpenTime && _isCompleting)
                  ? null
                  : (isOpenTime
                      ? () => _completeOpenTimeSession(context)
                      : () => ExtendSessionDialog.show(context, activeBooking)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _completeOpenTimeSession(BuildContext context) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      final bookingCubit = context.read<BookingCubit>();
      final roomCubit = context.read<RoomCubit>();
      final result = await bookingCubit.completeOpenTimeSession(widget.activeBooking.id);

      if (!context.mounted) return;

      if (result == null) {
        final message = bookingCubit.state.errorMessage ?? AppStrings.failedToCompleteOpenTime;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.danger),
        );
        return;
      }

      roomCubit.watchRooms(widget.activeBooking.loungeId, forceRefresh: true);
      final total = result['final_total'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            total == null
                ? AppStrings.openTimeCompletedSuccess
                : '${AppStrings.openTimeCompletedSuccess}. ${AppStrings.totalPrice}: $total ${AppStrings.egp}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }
}
