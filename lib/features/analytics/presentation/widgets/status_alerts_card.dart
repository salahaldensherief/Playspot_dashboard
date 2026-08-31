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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.systemHealth,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 16.h),
          AlertItem(
            icon: Icons.access_time_filled_outlined,
            label: AppStrings.shiftActive,
            value: openShifts.toString(),
            color: openShifts > 0 ? AppColors.success : AppColors.warning,
          ),
          SizedBox(height: 12.h),
          AlertItem(
            icon: Icons.inventory_2_outlined,
            label: AppStrings.lowStock,
            value: lowStock.toString(),
            color: lowStock > 0 ? AppColors.danger : AppColors.success,
          ),
        ],
      ),
    );
  }
}
