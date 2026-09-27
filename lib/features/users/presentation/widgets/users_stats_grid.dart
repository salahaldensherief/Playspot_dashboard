import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/stat_card.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import '../cubit/admin_management_cubit.dart';
import '../cubit/admin_management_state.dart';

class UsersStatsGrid extends StatelessWidget {
  const UsersStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminManagementCubit, AdminManagementState>(
      buildWhen: (previous, current) =>
          previous.status != current.status || previous.admins != current.admins,
      builder: (context, state) {
        final totalUsers = state.admins.length;
        final totalReferrals = state.admins.fold<int>(
          0,
          (sum, user) => sum + user.referralCount,
        );
        final totalPoints = state.admins.fold<int>(
          0,
          (sum, user) => sum + user.pointsBalance,
        );

        final isMobile = Responsive.isMobile(context);
        if (isMobile) {
          return Column(
            children: [
              StatCard(
                title: AppStrings.users,
                value: '$totalUsers',
                trendValue: 0.0,
                icon: Icons.people_outline,
                iconColor: AppColors.neonPurple,
              ),
              SizedBox(height: 12.h),
              StatCard(
                title: AppStrings.totalReferrals,
                value: '$totalReferrals',
                trendValue: 0.0,
                icon: Icons.share_outlined,
                iconColor: AppColors.neonBlue,
              ),
              SizedBox(height: 12.h),
              StatCard(
                title: AppStrings.totalPointsBalance,
                value: '$totalPoints ${AppStrings.pointsUnit}',
                trendValue: 0.0,
                icon: Icons.stars_outlined,
                iconColor: AppColors.warning,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: StatCard(
                title: AppStrings.users,
                value: '$totalUsers',
                trendValue: 0.0,
                icon: Icons.people_outline,
                iconColor: AppColors.neonPurple,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: StatCard(
                title: AppStrings.totalReferrals,
                value: '$totalReferrals',
                trendValue: 0.0,
                icon: Icons.share_outlined,
                iconColor: AppColors.neonBlue,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: StatCard(
                title: AppStrings.totalPointsBalance,
                value: '$totalPoints ${AppStrings.pointsUnit}',
                trendValue: 0.0,
                icon: Icons.stars_outlined,
                iconColor: AppColors.warning,
              ),
            ),
          ],
        );
      },
    );
  }
}
