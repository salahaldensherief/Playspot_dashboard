import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

/// Blind Shift Closing Dialog.
/// Prompts the cashier ONLY for the physical counted cash (`p_counted_cash`) and notes.
/// Does NOT expose `expected_cash` prior to submission.
class CloseShiftDialog extends StatefulWidget {
  final Function(double actualCash, String? notes) onConfirm;

  const CloseShiftDialog({
    super.key,
    required this.onConfirm,
    double? expectedCash, // Ignored for blind closing compliance
  });

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  final _cashController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      content: Container(
        width: 400.w,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'confirm_cash_instruction'.tr(),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              AppTextField(
                controller: _cashController,
                label: AppStrings.actualCash,
                hintText: AppStrings.hintAmount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return AppStrings.fieldRequired;
                  if (double.tryParse(val.trim()) == null) return AppStrings.invalidNumber;
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
              final countedCash = double.parse(_cashController.text.trim());
              final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
              widget.onConfirm(countedCash, notes);
            }
          },
        ),
      ],
    );
  }
}
