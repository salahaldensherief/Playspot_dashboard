import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_adaptive_page_header.dart';

class BookingsHeader extends StatelessWidget {
  const BookingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptivePageHeader(
      title: AppStrings.liveBookingsFeed,
      subtitle: AppStrings.loungeOperationsDesc,
      secondaryAction: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8.r,
              height: 8.r,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            ),
            SizedBox(width: 8.w),
            Text(
              'مباشر | Live',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
