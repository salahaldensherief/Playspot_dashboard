import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  final bool isSuperAdmin;

  const DashboardHeader({super.key, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSuperAdmin ? AppStrings.globalOverview : AppStrings.loungePerformance,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          isSuperAdmin 
            ? AppStrings.globalPerformanceDesc
            : AppStrings.loungeOperationsDesc,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}
