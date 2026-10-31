import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import '../theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final double? trendValue;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final TextDirection? valueTextDirection;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.trendValue,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.valueTextDirection,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final bool isPositive = (trendValue ?? 0) >= 0;
    final String trendText =
        '${isPositive ? '+' : ''}${trendValue?.toStringAsFixed(1)}%';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  textDirection: valueTextDirection,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ] else if (trendValue != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive
                            ? AppColors.success
                            : AppColors.danger,
                        size: 13.r,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        trendText,
                        style: TextStyle(
                          color: isPositive
                              ? AppColors.success
                              : AppColors.danger,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        AppStrings.vsLastMonth,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: iconColor.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: iconColor, size: 20.r),
            ),
          ),
        ],
      ),
    );
  }
}
