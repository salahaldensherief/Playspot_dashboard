import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_info_chip.dart';

class BookingCardScheduleBox extends StatelessWidget {
  final Booking booking;
  final Color accent;
  final bool isOverdue;

  const BookingCardScheduleBox({
    super.key,
    required this.booking,
    required this.accent,
    required this.isOverdue,
  });

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      final time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String durationHrsStr =
        (booking.durationMinutes / 60.0).toStringAsFixed(1).replaceAll('.0', '');
    final String formattedDate = DateFormat('MMM dd').format(booking.date);
    final String? playMode = booking.playMode;
    final bool hasPlayMode = playMode != null && playMode.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time column
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                      size: 15.r,
                      color: isOverdue ? AppColors.danger : accent,
                    ),
                    SizedBox(width: 4.w),
                    AppText.subHeading(
                      _formatTime(booking.startTime),
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 11.r, color: AppColors.textMuted),
                    SizedBox(width: 4.w),
                    AppText.body(formattedDate, fontSize: 11.sp, color: AppColors.textMuted),
                    SizedBox(width: 6.w),
                    BookingInfoChip(
                      label: '$durationHrsStr ${AppStrings.hours}',
                      color: AppColors.neonPurple,
                    ),
                  ],
                ),
              ],
            ),

            Container(
              width: 1,
              margin: EdgeInsets.symmetric(horizontal: 10.w),
              color: AppColors.borderDefault,
            ),

            // Room column
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sports_esports_outlined, color: AppColors.neonPurple, size: 15.r),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: AppText.subHeading(
                          booking.roomName.isNotEmpty ? booking.roomName : AppStrings.roomLabel,
                          fontSize: 12.5.sp,
                          color: AppColors.textPrimary,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  if (hasPlayMode || booking.controllersCount > 0 || booking.screenSize.isNotEmpty) ...[
                    SizedBox(height: 5.h),
                    Wrap(
                      spacing: 4.w,
                      runSpacing: 4.h,
                      children: [
                        if (hasPlayMode)
                          BookingInfoChip(label: playMode, color: AppColors.neonBlue),
                        if (booking.controllersCount > 0)
                          BookingInfoChip(
                            label: '${booking.controllersCount} ${AppStrings.controllersLabel}',
                            icon: Icons.gamepad_outlined,
                            color: AppColors.textSecondary,
                          ),
                        if (booking.screenSize.isNotEmpty)
                          BookingInfoChip(
                            label: booking.screenSize,
                            icon: Icons.tv_outlined,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
