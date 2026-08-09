import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/stat_card.dart';

class DashboardStatsGrid extends StatelessWidget {
  final bool isSuperAdmin;

  const DashboardStatsGrid({super.key, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: isSuperAdmin ? 'Global Revenue' : AppStrings.dailyRevenue,
            value: isSuperAdmin ? '\$12,450' : '\$1,240',
            trend: '+12%',
            icon: Icons.payments_outlined,
            iconColor: AppColors.neonGreen,
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          child: StatCard(
            title: AppStrings.activeSessions,
            value: isSuperAdmin ? '184' : '42',
            trend: '+5',
            icon: Icons.sports_esports_outlined,
            iconColor: AppColors.neonBlue,
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          child: StatCard(
            title: AppStrings.loungeOccupancy,
            value: '84%',
            trend: '+2.4%',
            icon: Icons.meeting_room_outlined,
            iconColor: AppColors.neonPurple,
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          child: StatCard(
            title: isSuperAdmin ? 'Lounges Online' : 'Active Rooms',
            value: isSuperAdmin ? '12/12' : '8/10',
            trend: AppStrings.systemHealth,
            icon: isSuperAdmin ? Icons.business : Icons.door_front_door,
            iconColor: AppColors.neonCyan,
          ),
        ),
      ],
    );
  }
}
