import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

class LoungePerformanceItem extends StatelessWidget {
  final String name;
  final int bookings;
  final String revenue;
  final String trend;

  const LoungePerformanceItem({
    super.key,
    required this.name,
    required this.bookings,
    required this.revenue,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            color: AppColors.mutedBackground,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.business, color: AppColors.neonBlue, size: 20.r),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 3,
          child: AppText.subHeading(
            name,
            fontSize: 14.sp,
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(AppStrings.bookingsLabel, fontSize: 11.sp, color: AppColors.textMuted),
              AppText.body('$bookings', fontSize: 13.sp),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(AppStrings.revenue, fontSize: 11.sp, color: AppColors.textMuted),
              AppText.body(revenue, fontSize: 13.sp),
            ],
          ),
        ),
        if (trend.isNotEmpty)
          AppText.subHeading(
            trend,
            color: AppColors.success,
            fontSize: 13.sp,
          ),
      ],
    );
  }
}
