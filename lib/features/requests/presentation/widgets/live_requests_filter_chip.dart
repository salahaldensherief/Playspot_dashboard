import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';

class LiveRequestsFilterChip extends StatelessWidget {
  final String label;
  final RequestFilter filter;
  final RequestFilter currentFilter;
  final int count;
  final ValueChanged<RequestFilter> onSelected;

  const LiveRequestsFilterChip({
    super.key,
    required this.label,
    required this.filter,
    required this.currentFilter,
    this.count = 0,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = filter == currentFilter;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.body(
            label,
            color: isSelected ? Colors.black : AppColors.textPrimary,
            fontSize: 11.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          if (count > 0) ...[
            SizedBox(width: 4.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppColors.neonBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: AppText.body(
                '$count',
                color: isSelected ? Colors.black : AppColors.neonBlue,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      selectedColor: AppColors.neonBlue,
      backgroundColor: AppColors.mutedBackground,
      side: BorderSide(color: isSelected ? AppColors.neonBlue : AppColors.borderDefault),
      onSelected: (selected) {
        if (selected) onSelected(filter);
      },
    );
  }
}
