import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class OwnerInfoForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const OwnerInfoForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.loungeOwnerAdmin,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.ownerName,
                hintText: AppStrings.ownerNameHint,
                controller: nameController,
                validator: AppValidator.validateRequired,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.ownerEmail,
                hintText: AppStrings.emailHint,
                controller: emailController,
                validator: AppValidator.validateEmail,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.ownerPassword,
                hintText: AppStrings.passwordHint,
                controller: passwordController,
                isPassword: true,
                validator: AppValidator.validatePassword,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
