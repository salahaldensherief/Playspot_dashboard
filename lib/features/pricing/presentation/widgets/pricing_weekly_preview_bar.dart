import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/theme/app_colors.dart';

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

  static List<String> get dayNames => [
    'calendar_monday_short'.tr(),
    'calendar_tuesday_short'.tr(),
    'calendar_wednesday_short'.tr(),
    'calendar_thursday_short'.tr(),
    'calendar_friday_short'.tr(),
    'calendar_saturday_short'.tr(),
    'calendar_sunday_short'.tr(),
  ];

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
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'pricing_weekly_preview_title'.tr(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildLegendDot(AppColors.warning, 'pricing_peak'.tr()),
                  _buildLegendDot(AppColors.success, 'pricing_off_peak'.tr()),
                  _buildLegendDot(
                    AppColors.borderDefault,
                    'pricing_regular'.tr(),
                  ),
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
      mainAxisSize: MainAxisSize.min,
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
