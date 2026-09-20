import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

/// Live Countdown Timer widget for cash bookings
class BookingCountdownTimer extends StatefulWidget {
  final Booking booking;
  final int gracePeriodMinutes;

  const BookingCountdownTimer({
    super.key,
    required this.booking,
    this.gracePeriodMinutes = 15,
  });

  @override
  State<BookingCountdownTimer> createState() => _BookingCountdownTimerState();
}

class _BookingCountdownTimerState extends State<BookingCountdownTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.booking.startDateTime;
    if (start == null) return const SizedBox.shrink();

    final now = DateTime.now();

    if (now.isBefore(start)) {
      // Countdown to start time
      final diff = start.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      final seconds = diff.inSeconds.remainder(60);

      final String timeFormatted = hours > 0
          ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
          : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 12.r),
            SizedBox(width: 4.w),
            Text(
              AppStrings.countdownToStart(timeFormatted),
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      // Past start time - grace period tracking
      final elapsed = now.difference(start);
      final elapsedMins = elapsed.inMinutes;
      final graceLimit = widget.gracePeriodMinutes;

      final isExpired = elapsedMins >= graceLimit;

      if (isExpired) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 12.r),
              SizedBox(width: 4.w),
              Text(
                AppStrings.gracePeriodExpired(graceLimit.toString()),
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      } else {
        final remainingGraceSecs = (graceLimit * 60) - elapsed.inSeconds;
        final mins = (remainingGraceSecs / 60).floor();
        final secs = remainingGraceSecs % 60;
        final formattedGrace = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_off_outlined, color: AppColors.danger, size: 12.r),
              SizedBox(width: 4.w),
              Text(
                'تأخير $formattedGrace د (من مهلة $graceLimit د)',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}
