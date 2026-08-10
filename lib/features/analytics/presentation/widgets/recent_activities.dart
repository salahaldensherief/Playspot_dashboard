import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.heading(
                AppStrings.recentActivity,
                fontSize: 18.sp,
              ),
              TextButton(
                onPressed: () {},
                child: AppText.body(
                  AppStrings.viewAll,
                  color: AppColors.neonBlue,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          const _ActivityItem(
            user: 'Salah Sheref',
            action: 'confirmed a new booking at',
            target: 'Arena Zone',
            time: '2 mins ago',
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
          ),
          const _ActivityItem(
            user: 'System',
            action: 'generated weekly revenue report for',
            target: 'All Lounges',
            time: '1 hour ago',
            icon: Icons.description_outlined,
            iconColor: AppColors.neonCyan,
          ),
          const _ActivityItem(
            user: 'Admin 02',
            action: 'added a new promotion',
            target: 'Summer Sale 20% OFF',
            time: '3 hours ago',
            icon: Icons.local_offer_outlined,
            iconColor: AppColors.neonPurple,
          ),
          const _ActivityItem(
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

class _ActivityItem extends StatelessWidget {
  final String user;
  final String action;
  final String target;
  final String time;
  final IconData icon;
  final Color iconColor;

  const _ActivityItem({
    required this.user,
    required this.action,
    required this.target,
    required this.time,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16.r),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      TextSpan(
                        text: user,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' $action '),
                      TextSpan(
                        text: target,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                AppText.body(
                  time,
                  color: AppColors.textMuted,
                  fontSize: 11.sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
