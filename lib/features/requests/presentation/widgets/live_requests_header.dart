import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

class LiveRequestsHeader extends StatelessWidget {
  final int unreadCount;
  final bool isLoading;

  const LiveRequestsHeader({
    super.key,
    required this.unreadCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                color: AppColors.neonBlue,
                size: 20.r,
              ),
            ),
            SizedBox(width: 10.w),
            AppText.heading(
              AppStrings.requestsFeed,
              fontSize: 16.sp,
            ),
            if (unreadCount > 0) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.neonBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: AppText.body(
                  '$unreadCount',
                  color: AppColors.neonBlue,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        if (isLoading)
          SizedBox(
            width: 16.r,
            height: 16.r,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}
