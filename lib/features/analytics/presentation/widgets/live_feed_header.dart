import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';

class LiveFeedHeader extends StatelessWidget {
  final int activeCount;
  final bool isLoading;

  const LiveFeedHeader({required this.activeCount, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 12.r,
                height: 12.r,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.w),
              Flexible(
                child: AppText.heading(
                  AppStrings.activeSessions,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.neonBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: AppText.body(
                  '$activeCount',
                  color: AppColors.neonBlue,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
