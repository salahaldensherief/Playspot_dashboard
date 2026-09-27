import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

/// Live session progress. Owns a light timer so the bar and the remaining
/// minutes stay fresh without the parent list having to rebuild.
class BookingSessionProgress extends StatefulWidget {
  final Booking booking;

  const BookingSessionProgress({super.key, required this.booking});

  @override
  State<BookingSessionProgress> createState() => _BookingSessionProgressState();
}

class _BookingSessionProgressState extends State<BookingSessionProgress> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
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
    final end = widget.booking.endDateTime;
    final now = DateTime.now();

    int remainingMins = 0;
    double progress = 0.0;

    if (start != null && end != null) {
      final totalDuration = end.difference(start).inMinutes;
      final elapsed = now.difference(start).inMinutes;
      if (totalDuration > 0) {
        progress = (elapsed / totalDuration).clamp(0.0, 1.0);
        remainingMins = (totalDuration - elapsed).clamp(0, 999).toInt();
      }
    }

    final bool almostDone = remainingMins <= 5;
    final String remainingText = remainingMins > 0
        ? '${AppStrings.remaining}: $remainingMins ${AppStrings.minutesUnit}'
        : AppStrings.timeUp;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 13.r, color: AppColors.success),
                  SizedBox(width: 4.w),
                  AppText.body(
                    AppStrings.sessionActive,
                    fontSize: 11.sp,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              AppText.body(
                remainingText,
                fontSize: 11.sp,
                color: almostDone ? AppColors.warning : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5.h,
              backgroundColor: AppColors.mutedBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9 ? AppColors.warning : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
