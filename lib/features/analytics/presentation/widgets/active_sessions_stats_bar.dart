import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';

class ActiveSessionsStatsBar extends StatelessWidget {
  final int activeCount;
  final double totalRevenue;
  final int extrasCount;

  const ActiveSessionsStatsBar({
    super.key,
    required this.activeCount,
    required this.totalRevenue,
    required this.extrasCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStatTile(
              title: AppStrings.activeSessions,
              value: '$activeCount',
              icon: Icons.sports_esports,
              color: AppColors.neonBlue,
            ),
          ),
          Container(width: 1.w, height: 28.h, color: AppColors.divider),
          Expanded(
            child: _MiniStatTile(
              title: AppStrings.activeSessionRevenue,
              value: '${totalRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
              icon: Icons.account_balance_wallet,
              color: AppColors.neonGreen,
            ),
          ),
          Container(width: 1.w, height: 28.h, color: AppColors.divider),
          Expanded(
            child: _MiniStatTile(
              title: AppStrings.totalActiveExtras,
              value: '$extrasCount',
              icon: Icons.restaurant,
              color: AppColors.neonCyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18.r, color: color),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(title, fontSize: 10.sp, color: AppColors.textMuted),
            AppText.subHeading(
              value,
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ],
    );
  }
}
