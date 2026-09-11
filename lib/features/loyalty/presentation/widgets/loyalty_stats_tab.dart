import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../art_core/widgets/stat_card.dart';
import '../../data/models/loyalty_stats_model.dart';

class LoyaltyStatsTab extends StatelessWidget {
  final LoyaltyStatsModel stats;

  const LoyaltyStatsTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          // Top Stat Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int crossAxisCount = width > 1200 ? 5 : (width > 800 ? 3 : 2);

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    title: AppStrings.totalAddedPoints,
                    value: '${stats.totalAddedPoints} ${AppStrings.pointsUnit}',
                    icon: Icons.stars_rounded,
                    iconColor: AppColors.neonBlue,
                    trendValue: 0.0,
                  ),
                  StatCard(
                    title: AppStrings.totalReferrals,
                    value: '${stats.totalReferrals}',
                    icon: Icons.people_outline,
                    iconColor: AppColors.neonPurple,
                    trendValue: 0.0,
                  ),
                  StatCard(
                    title: AppStrings.completedReferrals,
                    value: '${stats.completedReferrals}',
                    icon: Icons.task_alt_rounded,
                    iconColor: AppColors.success,
                    trendValue: 0.0,
                  ),
                  StatCard(
                    title: AppStrings.totalReferralPoints,
                    value: '${stats.totalReferralPoints} ${AppStrings.pointsUnit}',
                    icon: Icons.card_giftcard,
                    iconColor: AppColors.warning,
                    trendValue: 0.0,
                  ),
                  StatCard(
                    title: AppStrings.totalVouchersIssued,
                    value: '${stats.totalVouchersIssued}',
                    icon: Icons.confirmation_number_outlined,
                    iconColor: AppColors.neonCyan,
                    trendValue: 0.0,
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 32.h),

          // User Distribution Per Level Section
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subHeading(AppStrings.usersPerLevel, fontSize: 20.sp),
                SizedBox(height: 16.h),
                if (stats.userCountByLevel.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: AppText.body(AppStrings.noResultsMatching, color: AppColors.textSecondary),
                    ),
                  )
                else
                  Wrap(
                    spacing: 24.w,
                    runSpacing: 16.h,
                    children: stats.userCountByLevel.entries.map((entry) {
                      return _buildLevelBadge(entry.key, entry.value);
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(String levelName, int userCount) {
    Color badgeColor = AppColors.neonBlue;
    String localizedName = levelName;

    if (levelName.contains('برونزي') || levelName.toLowerCase().contains('bronze')) {
      badgeColor = const Color(0xFFCD7F32);
      localizedName = AppStrings.levelBronze;
    } else if (levelName.contains('فضي') || levelName.toLowerCase().contains('silver')) {
      badgeColor = const Color(0xFFC0C0C0);
      localizedName = AppStrings.levelSilver;
    } else if (levelName.contains('ذهبي') || levelName.toLowerCase().contains('gold')) {
      badgeColor = const Color(0xFFFFD700);
      localizedName = AppStrings.levelGold;
    } else if (levelName.contains('بلاتيني') || levelName.toLowerCase().contains('platinum')) {
      badgeColor = const Color(0xEFE5E4E2);
      localizedName = AppStrings.levelPlatinum;
    }

    return Container(
      width: 200.w,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: badgeColor, size: 24.r),
              SizedBox(width: 8.w),
              AppText.body(localizedName, fontWeight: FontWeight.bold, fontSize: 16.sp),
            ],
          ),
          SizedBox(height: 12.h),
          AppText.heading('$userCount', fontSize: 24.sp, color: badgeColor),
          AppText.body(AppStrings.usersInLevel, fontSize: 12.sp, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
