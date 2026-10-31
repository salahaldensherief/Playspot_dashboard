import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/radial_countdown_ring.dart';

class LiveSessionTimerBox extends StatelessWidget {
  final Booking booking;
  final Color accent;
  final bool isExpired;
  final Duration remaining;
  final VoidCallback onOpenStationControl;
  final ValueChanged<int> onExtendMinutes;

  const LiveSessionTimerBox({
    super.key,
    required this.booking,
    required this.accent,
    required this.isExpired,
    required this.remaining,
    required this.onOpenStationControl,
    required this.onExtendMinutes,
  });

  String _formatTime12Hour(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, hour, minute);
        return DateFormat('hh:mm a').format(dt);
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }

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
    EasyLocalization.of(context);
    final formattedTime = _formatDuration(remaining);
    final String durationHrs = (booking.durationMinutes / 60.0)
        .toStringAsFixed(1)
        .replaceAll('.0', '');

    final String timerHeaderTitle = isExpired
        ? AppStrings.timeExpired
        : (booking.isOpenEnded
              ? AppStrings.elapsedTime
              : AppStrings.remainingTime);

    final String subtitleText = booking.isOpenEnded
        ? '${_formatTime12Hour(booking.startTime)} • ${'cashier.open'.tr()}'
        : '${_formatTime12Hour(booking.startTime)} ($durationHrs ${AppStrings.hours})';

    return Column(
      children: [
        InkWell(
          onTap: onOpenStationControl,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                RadialCountdownRing(
                  totalDuration: Duration(minutes: booking.durationMinutes),
                  remainingDuration: remaining,
                  isExpired: isExpired,
                  isOpenEnded: booking.isOpenEnded,
                  showText: false,
                  size: 38.0,
                  strokeWidth: 3.5,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body(
                        timerHeaderTitle,
                        fontSize: 11.5.sp,
                        color: isExpired
                            ? AppColors.danger
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      AppText.body(
                        subtitleText,
                        fontSize: 10.5.sp,
                        color: AppColors.textMuted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 130.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppText.subHeading(
                      isExpired ? '-$formattedTime' : formattedTime,
                      fontSize: 22.sp,
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!booking.isOpenEnded) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildExtendChip(
                  label: 'extend_15_minutes_short'.tr(),
                  minutes: 15,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildExtendChip(
                  label: 'extend_30_minutes_short'.tr(),
                  minutes: 30,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildExtendChip(
                  label: 'extend_1_hour_short'.tr(),
                  minutes: 60,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExtendChip({required String label, required int minutes}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: () => onExtendMinutes(minutes),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.neonBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.25)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 12.sp, color: AppColors.neonBlue),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(
                color: AppColors.neonBlue,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
