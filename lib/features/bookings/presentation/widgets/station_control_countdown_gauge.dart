import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/radial_countdown_ring.dart';

class StationControlCountdownGauge extends StatelessWidget {
  final Booking booking;
  final Duration remaining;
  final bool isExpired;
  final Color accent;

  const StationControlCountdownGauge({
    super.key,
    required this.booking,
    required this.remaining,
    required this.isExpired,
    required this.accent,
  });

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.abs();
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    if (totalSeconds >= 3600) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = Duration(minutes: booking.durationMinutes);

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          RadialCountdownRing(
            totalDuration: totalDuration,
            remainingDuration: remaining,
            isExpired: isExpired,
            isOpenEnded: booking.isOpenEnded,
            size: 68.0,
            strokeWidth: 5.0,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? AppStrings.timeExpired : AppStrings.remainingTime,
                  style: TextStyle(
                    color: isExpired ? AppColors.danger : AppColors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  booking.isOpenEnded ? 'الوقت مفتوح' : _formatDuration(remaining),
                  style: TextStyle(
                    color: isExpired ? AppColors.danger : AppColors.neonBlue,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppStrings.totalDuration('${booking.durationMinutes} دقيقة'),
                  style: TextStyle(
                    color: AppColors.textMuted,
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
