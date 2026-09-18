import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

/// Interactive Room & Session Discount Modal Dialog
/// Enables cashiers/managers to apply a room-specific discount
/// by Percentage (%) or Fixed Amount (EGP) with a mandatory audit reason.
class RoomDiscountDialog extends StatefulWidget {
  final String roomName;
  final double currentPrice;
  final Function(double discountAmount, double discountPercentage, String reason) onApplyDiscount;

  const RoomDiscountDialog({
    super.key,
    required this.roomName,
    required this.currentPrice,
    required this.onApplyDiscount,
  });

  @override
  State<RoomDiscountDialog> createState() => _RoomDiscountDialogState();
}

class _RoomDiscountDialogState extends State<RoomDiscountDialog> {
  bool _isPercentage = true;
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  double get _inputValue => double.tryParse(_valueController.text.trim()) ?? 0.0;

  double get _calculatedDiscountAmount {
    if (_isPercentage) {
      return (widget.currentPrice * _inputValue / 100).clamp(0.0, widget.currentPrice);
    }
    return _inputValue.clamp(0.0, widget.currentPrice);
  }

  double get _calculatedDiscountPercentage {
    if (_isPercentage) {
      return _inputValue.clamp(0.0, 100.0);
    }
    return widget.currentPrice > 0 ? (_inputValue / widget.currentPrice * 100).clamp(0.0, 100.0) : 0.0;
  }

  double get _finalPrice => (widget.currentPrice - _calculatedDiscountAmount).clamp(0.0, double.infinity);

  void _handleConfirm() {
    final reason = _reasonController.text.trim();
    if (_inputValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى أدخال نسبة أو مبلغ خصم صحيح'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.reasonRequired),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    widget.onApplyDiscount(
      _calculatedDiscountAmount,
      _calculatedDiscountPercentage,
      reason,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
      child: Container(
        width: 420.w,
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_offer_rounded, color: AppColors.warning, size: 20.r),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.subHeading(
                        'إضافة خصم على [ ${widget.roomName} ]',
                        fontSize: 15.sp,
                        color: AppColors.textPrimary,
                      ),
                      AppText.body(
                        'السعر الإجمالي الحالي: ${widget.currentPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                        fontSize: 11.sp,
                        color: AppColors.neonBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Discount Type Toggle Tabs
            Container(
              padding: EdgeInsets.all(3.r),
              decoration: BoxDecoration(
                color: AppColors.mutedBackground,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isPercentage = true),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          color: _isPercentage ? AppColors.neonBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'نسبة مئوية (%)',
                          style: TextStyle(
                            color: _isPercentage ? Colors.black : AppColors.textSecondary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isPercentage = false),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          color: !_isPercentage ? AppColors.neonBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'مبلغ ثابت (ج.م)',
                          style: TextStyle(
                            color: !_isPercentage ? Colors.black : AppColors.textSecondary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Value Input Field
            AppText.body(
              _isPercentage ? 'نسبة الخصم (%):' : 'مبلغ الخصم (ج.م):',
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _isPercentage ? 'مثال: 15' : 'مثال: 30',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                filled: true,
                fillColor: AppColors.mutedBackground,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                suffixIcon: Icon(
                  _isPercentage ? Icons.percent : Icons.payments_outlined,
                  color: AppColors.neonBlue,
                  size: 18.r,
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Reason Input Field
            AppText.body(
              'سبب الخصم (مطلوب للرقابة المالية):',
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _reasonController,
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: 'مثال: عرض ساعات الصباح / تعويض عميل',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                filled: true,
                fillColor: AppColors.mutedBackground,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Calculation Summary Card
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.mutedBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body(
                        'خصم: ${_calculatedDiscountAmount.toStringAsFixed(0)} ${AppStrings.egp} (${_calculatedDiscountPercentage.toStringAsFixed(0)}%)',
                        fontSize: 11.sp,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: 2.h),
                      AppText.body(
                        'السعر قبل الخصم: ${widget.currentPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                        fontSize: 10.sp,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText.body('الصافي النهائي:', fontSize: 10.sp, color: AppColors.textMuted),
                      AppText.subHeading(
                        '${_finalPrice.toStringAsFixed(0)} ${AppStrings.egp}',
                        fontSize: 15.sp,
                        color: AppColors.neonGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: AppStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppButton(
                    text: 'تطبيق الخصم',
                    onPressed: _handleConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
