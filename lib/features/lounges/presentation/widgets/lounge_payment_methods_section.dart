import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

class LoungePaymentMethodsSection extends StatelessWidget {
  final TextEditingController vodafoneCashController;
  final TextEditingController instapayController;

  const LoungePaymentMethodsSection({
    super.key,
    required this.vodafoneCashController,
    required this.instapayController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_rounded, color: AppColors.neonBlue),
              SizedBox(width: 8.w),
              Text(
                AppStrings.paymentMethodsTitle,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.paymentMethodsHint,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 16.h),
          AppTextField(
            controller: vodafoneCashController,
            label: AppStrings.vodafoneCashNumberStr,
            hintText: AppStrings.hintPhoneNumber,
          ),
          SizedBox(height: 16.h),
          AppTextField(
            controller: instapayController,
            label: AppStrings.instapayAccountStr,
            hintText: AppStrings.hintInstapay,
          ),
        ],
      ),
    );
  }
}
