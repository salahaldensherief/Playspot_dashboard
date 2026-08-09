import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

class TopLoungesCard extends StatelessWidget {
  const TopLoungesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.topPerformingLounges,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            AppStrings.topPerformingLoungesSubtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 24.h),
          // Simplified table/list for now
          const _LoungeItem(name: 'Nexus Gaming Zone', bookings: 1240, revenue: '\$15,200', trend: '+12%'),
          Divider(color: AppColors.borderDefault, height: 24.h),
          const _LoungeItem(name: 'The Arena', bookings: 980, revenue: '\$12,800', trend: '+8%'),
          Divider(color: AppColors.borderDefault, height: 24.h),
          const _LoungeItem(name: 'Cyber Pulse', bookings: 850, revenue: '\$10,500', trend: '+15%'),
        ],
      ),
    );
  }
}

class _LoungeItem extends StatelessWidget {
  final String name;
  final int bookings;
  final String revenue;
  final String trend;

  const _LoungeItem({
    required this.name,
    required this.bookings,
    required this.revenue,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            color: AppColors.mutedBackground,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.business, color: AppColors.neonBlue, size: 20.r),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 3,
          child: Text(
            name,
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.sp),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bookings', style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
              Text('$bookings', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Revenue', style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
              Text(revenue, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
            ],
          ),
        ),
        Text(
          trend,
          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13.sp),
        ),
      ],
    );
  }
}
