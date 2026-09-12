import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

class OccupancyGaugeCard extends StatelessWidget {
  final int occupied;
  final int total;
  final double rate;

  const OccupancyGaugeCard({
    super.key,
    required this.occupied,
    required this.total,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.loungeOccupancy,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.meeting_room_outlined, color: AppColors.neonPurple, size: 20.r),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$occupied / $total',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 22.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(rate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: AppColors.neonPurple, fontSize: 13.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(width: 16.w),
                SizedBox(
                  width: 50.r,
                  height: 50.r,
                  child: CircularProgressIndicator(
                    value: rate,
                    strokeWidth: 6,
                    backgroundColor: AppColors.neonPurple.withValues(alpha: 0.1),
                    color: AppColors.neonPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
