import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'activity_item.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.heading(
                AppStrings.recentActivity,
                fontSize: 18.sp,
              ),
              TextButton(
                onPressed: () => context.push(RouterKeys.loungeAdminLiveOps),
                child: AppText.body(
                  AppStrings.viewAll,
                  color: AppColors.neonBlue,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ActivityItem(
            user: 'Salah Sheref',
            action: 'confirmed a new booking at',
            target: 'Arena Zone',
            time: '2 mins ago',
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
          ),
          ActivityItem(
            user: AppStrings.system,
            action: 'generated weekly revenue report for',
            target: 'All Lounges',
            time: '1 hour ago',
            icon: Icons.description_outlined,
            iconColor: AppColors.neonCyan,
          ),
          ActivityItem(
            user: 'Admin 02',
            action: 'added a new promotion',
            target: 'Summer Sale 20% OFF',
            time: '3 hours ago',
            icon: Icons.local_offer_outlined,
            iconColor: AppColors.neonPurple,
          ),
          ActivityItem(
            user: 'Lounge Admin',
            action: 'updated room availability in',
            target: 'Cyber Pulse',
            time: '5 hours ago',
            icon: Icons.sync,
            iconColor: AppColors.warning,
          ),
        ],
      ),
    );
  }
}
