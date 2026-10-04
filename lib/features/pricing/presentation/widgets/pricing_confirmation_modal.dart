import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';

class PricingConfirmationModal extends StatelessWidget {
  final int affectedRoomsCount;
  final VoidCallback onConfirm;

  const PricingConfirmationModal({
    super.key,
    required this.affectedRoomsCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return AppDialog(
      title: AppStrings.confirmSaveRule,
      width: 450.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: AppStrings.confirm,
          backgroundColor: AppColors.neonBlue,
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 28.r, color: AppColors.neonBlue),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  AppStrings.affectedRoomsNotice(affectedRoomsCount),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.mutedBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 20.r, color: AppColors.success),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    AppStrings.existingBookingsUnaffected,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
