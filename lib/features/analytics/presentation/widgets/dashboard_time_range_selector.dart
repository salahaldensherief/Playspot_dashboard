import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

enum DashboardTimeRange { day, week, month }

class DashboardTimeRangeSelector extends StatelessWidget {
  final DashboardTimeRange selectedRange;
  final ValueChanged<DashboardTimeRange> onRangeChanged;

  const DashboardTimeRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRangeChip(AppStrings.day, DashboardTimeRange.day),
          SizedBox(width: 4.w),
          _buildRangeChip(AppStrings.week, DashboardTimeRange.week),
          SizedBox(width: 4.w),
          _buildRangeChip(AppStrings.month, DashboardTimeRange.month),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, DashboardTimeRange range) {
    final bool isSelected = selectedRange == range;
    return InkWell(
      onTap: () => onRangeChanged(range),
      borderRadius: BorderRadius.circular(8.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonBlue.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.neonBlue : Colors.transparent,
          ),
        ),
        child: AppText.body(
          label,
          color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
          fontSize: 12.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
