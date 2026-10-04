import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

class LoungeOpenTimePolicySection extends StatelessWidget {
  final bool allowOpenTimeSessions;
  final TextEditingController roundingController;
  final TextEditingController minMinutesController;
  final TextEditingController maxMinutesController;
  final bool canEdit;
  final ValueChanged<bool> onAllowOpenTimeChanged;

  const LoungeOpenTimePolicySection({
    super.key,
    required this.allowOpenTimeSessions,
    required this.roundingController,
    required this.minMinutesController,
    required this.maxMinutesController,
    required this.canEdit,
    required this.onAllowOpenTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.all_inclusive_rounded,
                color: AppColors.neonCyan,
              ),
              SizedBox(width: 8.w),
              Text(
                AppStrings.openTimePolicySettingsTitle,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.openTimePolicySettingsDesc,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
          ),
          SizedBox(height: 16.h),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: allowOpenTimeSessions,
              onChanged: canEdit ? onAllowOpenTimeChanged : null,
              activeThumbColor: AppColors.neonCyan,
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppStrings.enableOpenTimeSessionsTitle,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                AppStrings.enableOpenTimeSessionsDesc,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5.sp,
                ),
              ),
            ),
          ),
          if (allowOpenTimeSessions) ...[
            const Divider(color: AppColors.borderDefault),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: minMinutesController,
                    label: AppStrings.minOpenTimeMinutesLabel,
                    hintText: '60',
                    keyboardType: TextInputType.number,
                    enabled: canEdit,
                    prefixIcon: Icons.hourglass_bottom_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return AppStrings.invalidNumberError;
                      final parsed = int.tryParse(value.trim());
                      if (parsed == null || parsed < 15 || parsed > 240) {
                        return AppStrings.invalidNumberError;
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppTextField(
                    controller: roundingController,
                    label: AppStrings.openTimeRoundingMinutesLabel,
                    hintText: '15',
                    keyboardType: TextInputType.number,
                    enabled: canEdit,
                    prefixIcon: Icons.update_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return AppStrings.invalidNumberError;
                      final parsed = int.tryParse(value.trim());
                      if (![5, 10, 15, 30, 60].contains(parsed)) {
                        return AppStrings.invalidNumberError;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            AppTextField(
              controller: maxMinutesController,
              label: AppStrings.maxOpenTimeMinutesLabel,
              hintText: AppStrings.maxOpenTimeMinutesHint,
              keyboardType: TextInputType.number,
              enabled: canEdit,
              prefixIcon: Icons.timer_off_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return AppStrings.invalidNumberError;
                final parsed = int.tryParse(value.trim());
                final minimum = int.tryParse(minMinutesController.text.trim());
                if (parsed == null ||
                    parsed < 60 ||
                    parsed > 1440 ||
                    (minimum != null && parsed < minimum)) {
                  return AppStrings.invalidNumberError;
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
}
