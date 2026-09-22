import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/responsive/app_breakpoints.dart';

class AppAdaptivePageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  const AppAdaptivePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.primaryAction,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.heading(title, fontSize: 20.sp),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            SizedBox(height: 4.h),
            AppText.body(subtitle!, fontSize: 13.sp, color: AppColors.textSecondary),
          ],
          if (primaryAction != null || secondaryAction != null) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                if (secondaryAction != null) ...[
                  Expanded(child: secondaryAction!),
                  if (primaryAction != null) SizedBox(width: 8.w),
                ],
                if (primaryAction != null) Expanded(child: primaryAction!),
              ],
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (primaryAction != null || secondaryAction != null) ...[
          SizedBox(width: 16.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (secondaryAction != null) ...[
                secondaryAction!,
                if (primaryAction != null) SizedBox(width: 12.w),
              ],
              if (primaryAction != null) primaryAction!,
            ],
          ),
        ],
      ],
    );
  }
}
