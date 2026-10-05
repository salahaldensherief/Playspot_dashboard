import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

/// Interactive Room & Session Discount Modal Dialog
/// Enables cashiers/managers to apply a room-specific discount
/// by Percentage (%) or Fixed Amount (EGP) with a mandatory audit reason.
class RoomDiscountDialog extends StatefulWidget {
  final String roomName;
  final double currentPrice;
  final Function(
    double discountAmount,
    double discountPercentage,
    String reason,
  )
  onApplyDiscount;

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
  final _scrollController = ScrollController();
  bool _isPercentage = true;
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  double get _inputValue =>
      double.tryParse(_valueController.text.trim()) ?? 0.0;

  double get _calculatedDiscountAmount {
    if (_isPercentage) {
      return (widget.currentPrice * _inputValue / 100).clamp(
        0.0,
        widget.currentPrice,
      );
    }
    return _inputValue.clamp(0.0, widget.currentPrice);
  }

  double get _calculatedDiscountPercentage {
    if (_isPercentage) {
      return _inputValue.clamp(0.0, 100.0);
    }
    return widget.currentPrice > 0
        ? (_inputValue / widget.currentPrice * 100).clamp(0.0, 100.0)
        : 0.0;
  }

  double get _finalPrice => (widget.currentPrice - _calculatedDiscountAmount)
      .clamp(0.0, double.infinity);

  void _handleConfirm() {
    final reason = _reasonController.text.trim();
    if (_inputValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('invalid_room_discount'.tr()),
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
    EasyLocalization.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(440.w, screenSize.width - 32);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Padding(
              padding: EdgeInsets.fromLTRB(20.r, 20.r, 20.r, 12.r),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_offer_rounded,
                      color: AppColors.warning,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.subHeading(
                          'room_discount_title'.tr(
                            args: [(widget.roomName).toString()],
                          ),
                          fontSize: 15.sp,
                          color: AppColors.textPrimary,
                        ),
                        AppText.body(
                          'current_price_label'.tr(
                            args: [
                              (widget.currentPrice.toStringAsFixed(0)).toString(),
                              (AppStrings.egp).toString(),
                            ],
                          ),
                          fontSize: 11.sp,
                          color: AppColors.neonBlue,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon:
                        const Icon(Icons.close, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            // Scrollable Body
            Flexible(
              child: Scrollbar(
                thumbVisibility: true,
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.r, vertical: 16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          color: _isPercentage
                              ? AppColors.neonBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'discount_percentage_label'.tr(),
                          style: TextStyle(
                            color: _isPercentage
                                ? Colors.black
                                : AppColors.textSecondary,
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
                          color: !_isPercentage
                              ? AppColors.neonBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'discount_fixed_egp_label'.tr(),
                          style: TextStyle(
                            color: !_isPercentage
                                ? Colors.black
                                : AppColors.textSecondary,
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
            AppTextField(
              controller: _valueController,
              label: _isPercentage
                  ? AppStrings.discountPercentageInput
                  : AppStrings.discountAmountInput,
              hintText: _isPercentage
                  ? AppStrings.discountPercentageHint
                  : AppStrings.discountAmountHint,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
              onChanged: (_) => setState(() {}),
              suffix: Icon(
                _isPercentage ? Icons.percent : Icons.payments_outlined,
                color: AppColors.neonBlue,
                size: 18.r,
              ),
            ),
            SizedBox(height: 12.h),

            // Reason Input Field
            AppTextField(
              controller: _reasonController,
              label: AppStrings.discountReasonRequiredLabel,
              hintText: AppStrings.roomDiscountReasonHint,
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
                        'discount_summary_label'.tr(
                          args: [
                            (_calculatedDiscountAmount.toStringAsFixed(
                              0,
                            )).toString(),
                            (AppStrings.egp).toString(),
                            (_calculatedDiscountPercentage.toStringAsFixed(
                              0,
                            )).toString(),
                          ],
                        ),
                        fontSize: 11.sp,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: 2.h),
                      AppText.body(
                        'price_before_discount_label'.tr(
                          args: [
                            (widget.currentPrice.toStringAsFixed(0)).toString(),
                            (AppStrings.egp).toString(),
                          ],
                        ),
                        fontSize: 10.sp,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText.body(
                        'final_net_total_label'.tr(),
                        fontSize: 10.sp,
                        color: AppColors.textMuted,
                      ),
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
          ],
        ),
      ),
    ),
  ),
            const Divider(height: 1, color: AppColors.divider),
            // Action Buttons
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
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
                      text: 'apply_discount'.tr(),
                      onPressed: _handleConfirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
