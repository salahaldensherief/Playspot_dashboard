import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

class StationControlHeader extends StatelessWidget {
  final Booking booking;
  final Color accent;
  final VoidCallback onClose;

  const StationControlHeader({
    super.key,
    required this.booking,
    required this.accent,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        border: const Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.sports_esports_rounded,
                  color: accent,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        booking.roomName.isNotEmpty ? booking.roomName : AppStrings.roomLabel,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      StatusBadge.success(AppStrings.inProgress.toUpperCase()),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    booking.playMode ?? "فردي",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20.sp),
          ),
        ],
      ),
    );
  }
}
