import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../../data/models/loyalty_stats_model.dart';

class LoyaltyStatsGrid extends StatelessWidget {
  final LoyaltyStatsModel stats;
  const LoyaltyStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          title: AppStrings.totalVouchersIssued,
          value: stats.totalVouchersIssued.toString(),
          icon: Icons.confirmation_number_outlined,
          color: AppColors.neonBlue,
        )),
        SizedBox(width: 24.w),
        Expanded(child: _StatCard(
          title: AppStrings.totalVouchersUsed,
          value: stats.totalVouchersUsed.toString(),
          icon: Icons.check_circle_outline,
          color: AppColors.success,
        )),
        SizedBox(width: 24.w),
        Expanded(child: _StatCard(
          title: AppStrings.totalVouchersActive,
          value: stats.totalVouchersActive.toString(),
          icon: Icons.timer_outlined,
          color: AppColors.warning,
        )),
        SizedBox(width: 24.w),
        Expanded(child: _StatCard(
          title: AppStrings.totalDiscountUsedValue,
          value: "${stats.totalDiscountValueUsed.toStringAsFixed(0)} ${AppStrings.egp}",
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.neonPurple,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

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
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 24.r),
          ),
          SizedBox(height: 16.h),
          AppText.body(title, color: AppColors.textSecondary, fontSize: 14.sp),
          SizedBox(height: 8.h),
          AppText.heading(value, fontSize: 24.sp),
        ],
      ),
    );
  }
}
