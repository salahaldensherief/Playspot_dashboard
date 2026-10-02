import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget chart;
  final IconData actionIcon;
  final Color actionIconColor;
  final bool expandChart;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.chart,
    required this.actionIcon,
    required this.actionIconColor,
    this.expandChart = true,
  });

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(actionIcon, color: actionIconColor, size: 20.r),
            ],
          ),
          const SizedBox(height: 16),
          if (expandChart)
            Expanded(child: chart)
          else
            SizedBox(
              height:
                  160 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
              child: chart,
            ),
        ],
      ),
    );
  }
}
