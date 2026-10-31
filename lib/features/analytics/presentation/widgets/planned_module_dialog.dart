import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';

class PlannedModuleDialog extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const PlannedModuleDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420.w),
        child: Padding(
          padding: EdgeInsetsDirectional.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 28.r),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 10.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  AppStrings.plannedDialogTitle,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsetsDirectional.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: AppColors.neonCyan,
                      size: 18.r,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        AppStrings.plannedDialogDesc,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: AppStrings.plannedDialogGotIt,
                  onPressed: () => Navigator.of(context).pop(),
                  variant: AppButtonVariant.primary,
                  height: 44.h,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
