import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
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

      final double amount = double.parse(_amountController.text.trim());
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
            const SnackBar(
              content: Text('تم تسجيل المصروفات / السحب النقدي بنجاح'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 480.w,
        padding: EdgeInsets.all(28.r),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedType == 'expense' ? Icons.receipt_long_outlined : Icons.move_to_inbox,
                      color: AppColors.warning,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppText.heading(
                      'تسجيل مصروفات / سحب نقدي',
                      fontSize: 18.sp,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Type Selector (Expense vs Cash Drop)
              AppText.body('نوع العملية', fontWeight: FontWeight.bold, fontSize: 12.sp),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: AppText.body(
                          'مصروفات تشغيلية',
                          color: _selectedType == 'expense' ? Colors.white : AppColors.textPrimary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: _selectedType == 'expense',
                      selectedColor: AppColors.neonBlue,
                      backgroundColor: AppColors.cardBackground,
                      side: BorderSide(
                        color: _selectedType == 'expense' ? AppColors.neonBlue : AppColors.borderDefault,
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
                          'سحب نقدي للفرع/الخزينة',
                          color: _selectedType == 'cash_drop' ? Colors.white : AppColors.textPrimary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: _selectedType == 'cash_drop',
                      selectedColor: AppColors.warning,
                      backgroundColor: AppColors.cardBackground,
                      side: BorderSide(
                        color: _selectedType == 'cash_drop' ? AppColors.warning : AppColors.borderDefault,
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
                label: 'المبلغ (جنيه)',
                hintText: '0.00',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: AppValidator.validateNumber,
              ),
              SizedBox(height: 16.h),

              // Reason / Purpose Field
              AppTextField(
                label: 'السبب / التفاصيل',
                hintText: 'أدخل سبب إخراج النقدية (مثال: شراء مستلزمات / سحب للخزنة)',
                controller: _reasonController,
                maxLines: 2,
                validator: AppValidator.validateRequired,
              ),
              SizedBox(height: 28.h),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: AppStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 12.w),
                  AppButton(
                    text: 'تأكيد التسجيل',
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
