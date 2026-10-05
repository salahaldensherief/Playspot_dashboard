import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import '../shift_cubit.dart';

class AddExpenseDialog extends StatefulWidget {
  final String shiftId;
  final String loungeId;

  const AddExpenseDialog({
    super.key,
    required this.shiftId,
    required this.loungeId,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String _selectedType = 'expense'; // 'expense' or 'cash_drop'
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final double amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final String reason = _reasonController.text.trim();

      final cubit = context.read<ShiftCubit>();
      final success = await cubit.addShiftExpense(
        shiftId: widget.shiftId,
        loungeId: widget.loungeId,
        amount: amount,
        reason: reason,
        type: _selectedType,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.expenseRegisteredSuccess),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return AppDialog(
      title: AppStrings.registerExpenseTitle,
      width: 500.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: AppStrings.confirmRegistration,
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selector (Expense vs Cash Drop)
            AppText.body(
              AppStrings.operationType,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                      child: AppText.body(
                        AppStrings.operationalExpense,
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: _selectedType == 'expense',
                    selectedColor: AppColors.neonBlue,
                    backgroundColor: AppColors.cardBackground,
                    side: BorderSide(
                      color: _selectedType == 'expense'
                          ? AppColors.neonBlue
                          : AppColors.borderDefault,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedType = 'expense');
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                      child: AppText.body(
                        AppStrings.cashDrop,
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: _selectedType == 'cash_drop',
                    selectedColor: AppColors.warning,
                    backgroundColor: AppColors.cardBackground,
                    side: BorderSide(
                      color: _selectedType == 'cash_drop'
                          ? AppColors.warning
                          : AppColors.borderDefault,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedType = 'cash_drop');
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),

            // Amount Field
            AppTextField(
              label: AppStrings.amountEgp,
              hintText: AppStrings.hintAmount,
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: AppValidator.validateNumber,
            ),
            SizedBox(height: 16.h),

            // Reason / Purpose Field
            AppTextField(
              label: AppStrings.reasonDetails,
              hintText: AppStrings.expenseReasonHint,
              controller: _reasonController,
              maxLines: 2,
              validator: AppValidator.validateRequired,
            ),
          ],
        ),
      ),
    );
  }
}
