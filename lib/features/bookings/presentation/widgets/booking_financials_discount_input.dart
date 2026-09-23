import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

class BookingFinancialsDiscountInput extends StatelessWidget {
  final TextEditingController discountController;
  final TextEditingController reasonController;
  final bool isPercentage;
  final ValueChanged<bool>? onTogglePercentage;
  final ValueChanged<String>? onChanged;

  const BookingFinancialsDiscountInput({
    super.key,
    required this.discountController,
    required this.reasonController,
    required this.isPercentage,
    this.onTogglePercentage,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        AppText.subHeading(AppStrings.discount, fontSize: 14.sp),
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                label: AppStrings.discount,
                controller: discountController,
                keyboardType: TextInputType.number,
                suffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => onTogglePercentage?.call(false),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        child: Text(
                          'EGP',
                          style: TextStyle(
                            color: !isPercentage ? AppColors.neonBlue : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => onTogglePercentage?.call(true),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        child: Text(
                          '%',
                          style: TextStyle(
                            color: isPercentage ? AppColors.neonBlue : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                onChanged: onChanged,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 3,
              child: AppTextField(
                label: AppStrings.discountReason,
                controller: reasonController,
                hintText: 'Reason for audit...',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
