import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../domain/entities/pricing_rule_entity.dart';

class PricingWeeklyPreviewBar extends StatelessWidget {
  final List<int> selectedDays;
  final String startTime;
  final String endTime;
  final String ruleType;

  const PricingWeeklyPreviewBar({
    super.key,
    required this.selectedDays,
    required this.startTime,
    required this.endTime,
    required this.ruleType,
  });

  static const List<String> dayNames = ['إث', 'ثلا', 'أرب', 'خم', 'جم', 'سب', 'أح'];

  int _parseHour(String timeStr) {
    if (timeStr.isEmpty) return 0;
    final parts = timeStr.split(':');
    if (parts.isEmpty) return 0;
    return int.tryParse(parts[0]) ?? 0;
  }

  Color _getHourColor(int day, int hour) {
    final startHour = _parseHour(startTime);
    final endHour = _parseHour(endTime);

    bool isHourSelected = false;
    if (selectedDays.contains(day)) {
      if (endHour <= startHour) {
        // Overnight
        isHourSelected = hour >= startHour || hour < endHour;
      } else {
        isHourSelected = hour >= startHour && hour < endHour;
      }
    }

    if (!isHourSelected) {
      return AppColors.borderDefault.withAlpha(50);
    }

    switch (ruleType) {
      case 'peak':
        return AppColors.warning;
      case 'off_peak':
        return AppColors.success;
      case 'custom':
        return AppColors.neonBlue;
      default:
        return AppColors.neonBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'معاينة الساعات الأسبوعية (24 ساعة × 7 أيام)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _buildLegendDot(AppColors.warning, 'ذروة'),
                  SizedBox(width: 8.w),
                  _buildLegendDot(AppColors.success, 'هدوء'),
                  SizedBox(width: 8.w),
                  _buildLegendDot(AppColors.borderDefault, 'عادي'),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Column(
            children: List.generate(7, (dayIndex) {
              final dayNumber = dayIndex + 1;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32.w,
                      child: Text(
                        dayNames[dayIndex],
                        style: TextStyle(
                          color: selectedDays.contains(dayNumber)
                              ? AppColors.neonBlue
                              : AppColors.textSecondary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: List.generate(24, (hour) {
                          return Expanded(
                            child: Container(
                              height: 12.h,
                              margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                              decoration: BoxDecoration(
                                color: _getHourColor(dayNumber, hour),
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp),
        ),
      ],
    );
  }
}
