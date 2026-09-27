import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

class LoungeCashPolicySection extends StatelessWidget {
  final bool allowCashPayment;
  final bool requirePrepaidFirstTime;
  final TextEditingController gracePeriodController;
  final bool canEdit;
  final ValueChanged<bool> onAllowCashChanged;
  final ValueChanged<bool> onRequirePrepaidChanged;

  const LoungeCashPolicySection({
    super.key,
    required this.allowCashPayment,
    required this.requirePrepaidFirstTime,
    required this.gracePeriodController,
    required this.canEdit,
    required this.onAllowCashChanged,
    required this.onRequirePrepaidChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                  const Icon(Icons.payments_outlined, color: AppColors.warning),
                  SizedBox(width: 8.w),
                  Text(
                    AppStrings.cashPoliciesTitle,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  value: allowCashPayment,
                  onChanged: canEdit ? onAllowCashChanged : null,
                  activeThumbColor: AppColors.neonBlue,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppStrings.allowCashPaymentLabel,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    AppStrings.allowCashPaymentHint,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5.sp,
                    ),
                  ),
                ),
              ),
              const Divider(color: AppColors.borderDefault),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  value: requirePrepaidFirstTime,
                  onChanged: canEdit ? onRequirePrepaidChanged : null,
                  activeThumbColor: AppColors.warning,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppStrings.requirePrepaidFirstTimeLabel,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    AppStrings.requirePrepaidFirstTimeHint,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Container(
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
                  const Icon(Icons.timer_outlined, color: AppColors.neonPurple),
                  SizedBox(width: 8.w),
                  Text(
                    AppStrings.cashGracePeriodLabel,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                AppStrings.cashGracePeriodHint,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 16.h),
              AppTextField(
                controller: gracePeriodController,
                label: AppStrings.gracePeriodFieldLabel,
                hintText: AppStrings.hintMinutes,
                keyboardType: TextInputType.number,
                enabled: canEdit,
                prefixIcon: Icons.access_time_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.gracePeriodRequiredError;
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null) {
                    return AppStrings.invalidNumberError;
                  }
                  if (parsed < 0 || parsed > 1440) {
                    return AppStrings.gracePeriodRangeError;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
