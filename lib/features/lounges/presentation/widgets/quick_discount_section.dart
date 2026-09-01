import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';

class QuickDiscountSection extends StatelessWidget {
  final bool hasDiscount;
  final ValueChanged<bool> onHasDiscountChanged;
  final TextEditingController percentageController;
  final TextEditingController titleArController;
  final TextEditingController titleEnController;
  final TextEditingController expirationController;
  final VoidCallback onExpirationTap;
  final VoidCallback onSave;
  final bool isSaving;

  const QuickDiscountSection({
    super.key,
    required this.hasDiscount,
    required this.onHasDiscountChanged,
    required this.percentageController,
    required this.titleArController,
    required this.titleEnController,
    required this.expirationController,
    required this.onExpirationTap,
    required this.onSave,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.directDiscount,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AppStrings.activateDiscount,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              Switch(
                value: hasDiscount,
                onChanged: onHasDiscountChanged,
                activeColor: AppColors.neonBlue,
              ),
            ],
          ),
          if (hasDiscount) ...[
            SizedBox(height: 24.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildField(
                    label: AppStrings.discountPercentage,
                    controller: percentageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    hint: '0-99',
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildField(
                    label: AppStrings.discountExpiration,
                    controller: expirationController,
                    readOnly: true,
                    onTap: onExpirationTap,
                    hint: 'YYYY-MM-DD',
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: AppStrings.discountTitleAr,
                    controller: titleArController,
                    hint: AppStrings.promoTitleArHint,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildField(
                    label: AppStrings.discountTitleEn,
                    controller: titleEnController,
                    hint: AppStrings.promoTitleEnHint,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 24.h),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              text: AppStrings.saveChanges,
              isLoading: isSaving,
              onPressed: onSave,
              width: 150.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
            filled: true,
            fillColor: AppColors.mutedBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }
}
