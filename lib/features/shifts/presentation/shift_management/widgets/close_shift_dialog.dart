import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/permission_extension.dart';

class CloseShiftDialog extends StatefulWidget {
  final double? expectedCash;
  final Function(double, String?) onConfirm;

  const CloseShiftDialog({super.key, required this.onConfirm, this.expectedCash});

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  final _cashController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final bool canViewExpected = context.hasPermission('shift_view_expected_cash');

    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Row(
        children: [
          Icon(Icons.lock_clock_outlined, color: AppColors.danger, size: 24.r),
          SizedBox(width: 12.w),
          Text(
            AppStrings.closeShift,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'confirm_cash_instruction'.tr(),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
            if (canViewExpected && widget.expectedCash != null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.neonBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.expectedCash, style: const TextStyle(color: AppColors.textSecondary)),
                    Text(
                      '${widget.expectedCash!.toStringAsFixed(2)} ${AppStrings.egp}',
                      style: const TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 24.h),
            AppTextField(
              controller: _cashController,
              label: AppStrings.actualCash,
              hintText: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.isEmpty) return AppStrings.fieldRequired;
                if (double.tryParse(val) == null) return AppStrings.invalidNumber;
                return null;
              },
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _notesController,
              label: AppStrings.notes,
              hintText: AppStrings.descriptionHint,
              maxLines: 2,
            ),
          ],
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 8.w),
        AppButton(
          text: AppStrings.closeShift,
          variant: AppButtonVariant.danger,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onConfirm(
                double.parse(_cashController.text),
                _notesController.text.isEmpty ? null : _notesController.text,
              );
            }
          },
        ),
      ],
    );
  }
}
