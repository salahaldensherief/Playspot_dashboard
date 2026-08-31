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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.loungeOccupancy,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
              Icon(Icons.meeting_room_outlined, color: AppColors.neonPurple, size: 20.r),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$occupied / $total',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 24.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(rate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: AppColors.neonPurple, fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60.r,
                height: 60.r,
                child: CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 8,
                  backgroundColor: AppColors.neonPurple.withOpacity(0.1),
                  color: AppColors.neonPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
