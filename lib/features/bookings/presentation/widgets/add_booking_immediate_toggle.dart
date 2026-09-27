import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

class AddBookingImmediateToggle extends StatelessWidget {
  final bool isImmediate;
  final ValueChanged<bool> onChanged;

  const AddBookingImmediateToggle({
    super.key,
    required this.isImmediate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isImmediate ? AppColors.neonBlue.withValues(alpha: 0.5) : AppColors.borderDefault,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: isImmediate ? AppColors.neonBlue : AppColors.textMuted,
                  size: 22.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body(
                        AppStrings.startSessionImmediatelyTitle,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                      AppText.body(
                        AppStrings.startSessionImmediatelySub,
                        fontSize: 11.sp,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isImmediate,
            activeTrackColor: AppColors.neonBlue.withValues(alpha: 0.4),
            activeThumbColor: AppColors.neonBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
