import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'alert_item.dart';

class StatusAlertsCard extends StatelessWidget {
  final int openShifts;
  final int lowStock;

  const StatusAlertsCard({
    super.key,
    required this.openShifts,
    required this.lowStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.systemHealth,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8.h),
            AlertItem(
              icon: Icons.access_time_filled_outlined,
              label: AppStrings.shiftActive,
              value: openShifts.toString(),
              color: openShifts > 0 ? AppColors.success : AppColors.warning,
            ),
            SizedBox(height: 6.h),
            AlertItem(
              icon: Icons.inventory_2_outlined,
              label: AppStrings.lowStock,
              value: lowStock.toString(),
              color: lowStock > 0 ? AppColors.danger : AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}
