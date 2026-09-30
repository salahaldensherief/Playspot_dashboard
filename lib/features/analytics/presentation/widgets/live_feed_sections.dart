import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';

class LiveFeedSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const LiveFeedSectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.r, color: color),
        SizedBox(width: 6.w),
        Flexible(child: AppText.subHeading(
          title,
          fontSize: 14.sp,
          color: color,
          fontWeight: FontWeight.bold,
        )),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class EmptyActiveSessionsState extends StatelessWidget {
  const EmptyActiveSessionsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 40.r,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 8.h),
            AppText.body(
              AppStrings.noActiveSessions,
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
          ],
        ),
      ),
    );
  }
}
