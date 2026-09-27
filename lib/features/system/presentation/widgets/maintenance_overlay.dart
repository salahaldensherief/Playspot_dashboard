import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

class MaintenanceOverlayWidget extends StatelessWidget {
  final String messageAr;
  final String messageEn;

  const MaintenanceOverlayWidget({
    super.key,
    required this.messageAr,
    required this.messageEn,
  });

  @override
  Widget build(BuildContext context) {
    final activeMessage = messageAr.trim().isNotEmpty
        ? messageAr
        : (messageEn.trim().isNotEmpty
            ? messageEn
            : 'النظام حالياً قيد الصيانة المبرمجة لتحديث الخدمات. يرجى إعادة المحاولة لاحقاً.');

    return Material(
      color: AppColors.scaffoldBackground.withAlpha(242),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Container(
            constraints: BoxConstraints(maxWidth: 480.w),
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.danger.withAlpha(100), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withAlpha(38),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.build_circle_outlined,
                    color: AppColors.danger,
                    size: 56.r,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  AppStrings.maintenanceModeSystem,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  activeMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.mutedBackground,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12.r,
                        height: 12.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.warning,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'جاري إجراء التحديثات والتحسينات...',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
