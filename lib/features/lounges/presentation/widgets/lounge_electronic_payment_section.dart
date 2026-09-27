import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

class LoungeElectronicPaymentSection extends StatelessWidget {
  final TextEditingController walletNumberController;
  final TextEditingController instapayHandleController;
  final bool canEdit;

  const LoungeElectronicPaymentSection({
    super.key,
    required this.walletNumberController,
    required this.instapayHandleController,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.neonBlue),
              SizedBox(width: 8.w),
              Text(
                AppStrings.paymentMethodsTitle,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            AppStrings.paymentMethodsHint,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 16.h),
          AppTextField(
            controller: walletNumberController,
            label: AppStrings.walletNumberFieldLabel,
            hintText: AppStrings.hintPhoneNumber,
            enabled: canEdit,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_android_rounded,
          ),
          SizedBox(height: 16.h),
          AppTextField(
            controller: instapayHandleController,
            label: AppStrings.instapayHandleFieldLabel,
            hintText: AppStrings.hintInstapay,
            enabled: canEdit,
            prefixIcon: Icons.alternate_email_rounded,
          ),
        ],
      ),
    );
  }
}
