import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

/// Redesigned Customer Visit Badge Component
/// Displays:
/// 1. ✨ عميل جديد (First Visit / New Customer)
/// 2. 🔁 الزيارة رقم N (Returning Customer - Standard)
/// 3. 👑 الزيارة #N (VIP) (Loyal Customer - 10+ Visits)
class CustomerVisitBadge extends StatelessWidget {
  final int? visitNumber;
  final double? fontSize;

  const CustomerVisitBadge({
    super.key,
    required this.visitNumber,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (visitNumber == null || visitNumber! <= 0) {
      return const SizedBox.shrink();
    }

    final double effectiveFontSize = fontSize ?? 9.5.sp;
    final bool isNewCustomer = visitNumber == 1;
    final bool isVipCustomer = visitNumber! >= 10;

    // 1. New Customer Badge (✨ عميل جديد)
    if (isNewCustomer) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: const Color(0x1F10B981), // 12% Translucent Emerald Green
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0x4010B981), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: effectiveFontSize + 1.r,
              color: const Color(0xFF10B981),
            ),
            SizedBox(width: 3.w),
            Text(
              AppStrings.newCustomer,
              style: TextStyle(
                color: const Color(0xFF10B981),
                fontSize: effectiveFontSize,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ],
        ),
      );
    }

    // 2. VIP Loyal Customer Badge (👑 10+ Visits)
    if (isVipCustomer) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0x28FFD700), Color(0x18A855F7)],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0x66FFD700), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: effectiveFontSize + 1.r,
              color: const Color(0xFFFFD700),
            ),
            SizedBox(width: 3.w),
            Text(
              AppStrings.visitVipCount(visitNumber!),
              style: TextStyle(
                color: const Color(0xFFFFD700),
                fontSize: effectiveFontSize,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ],
        ),
      );
    }

    // 3. Returning Customer Badge (🔁 الزيارة رقم N)
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.neonBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.25), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: effectiveFontSize + 1.r,
            color: AppColors.neonBlue,
          ),
          SizedBox(width: 3.w),
          Text(
            AppStrings.visitNumberCount(visitNumber!),
            style: TextStyle(
              color: AppColors.neonBlue,
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
