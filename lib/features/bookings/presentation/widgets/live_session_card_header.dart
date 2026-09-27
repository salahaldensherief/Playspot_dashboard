import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

class LiveSessionCardHeader extends StatelessWidget {
  final Booking booking;
  final Color accent;
  final VoidCallback onSwapRoom;
  final VoidCallback onOpenStationControl;

  const LiveSessionCardHeader({
    super.key,
    required this.booking,
    required this.accent,
    required this.onSwapRoom,
    required this.onOpenStationControl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.08),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.sports_esports_rounded, size: 16.r, color: accent),
                SizedBox(width: 6.w),
                Flexible(
                  child: AppText.subHeading(
                    booking.roomName,
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 6.w),
                Tooltip(
                  message: AppStrings.swapRoom,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6.r),
                    onTap: onSwapRoom,
                    child: Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: BoxDecoration(
                        color: AppColors.neonBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        size: 14,
                        color: AppColors.neonBlue,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Tooltip(
                  message: AppStrings.stationControlDrawer,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6.r),
                    onTap: onOpenStationControl,
                    child: Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: AppColors.neonPurple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          StatusBadge.success(AppStrings.inProgress.toUpperCase()),
        ],
      ),
    );
  }
}
