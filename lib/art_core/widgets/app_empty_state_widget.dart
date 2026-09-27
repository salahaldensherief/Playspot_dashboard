import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

class AppEmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onActionTextPressed;

  const AppEmptyStateWidget({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionTextPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.mutedBackground.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Icon(icon, color: AppColors.neonBlue, size: 48.r),
            ),
            SizedBox(height: 16.h),
            AppText.heading(title, fontSize: 18.sp, textAlign: TextAlign.center),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              SizedBox(height: 6.h),
              AppText.body(subtitle!, fontSize: 13.sp, color: AppColors.textSecondary, textAlign: TextAlign.center),
            ],
            if (actionText != null && onActionTextPressed != null) ...[
              SizedBox(height: 20.h),
              AppButton(
                text: actionText!,
                icon: Icons.refresh,
                variant: AppButtonVariant.outlined,
                onPressed: onActionTextPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
