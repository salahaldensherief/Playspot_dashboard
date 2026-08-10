import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

class BookingsHeader extends StatelessWidget {
  const BookingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12.r,
              height: 12.r,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            ),
            SizedBox(width: 12.w),
            AppText.heading(
              AppStrings.liveBookingsFeed,
              fontSize: 32.sp,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        AppText.body(
          AppStrings.loungeOperationsDesc,
          fontSize: 14.sp,
        ),
      ],
    );
  }
}
