import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

import 'package:flutter/services.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class AddBookingCustomerFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  const AddBookingCustomerFields({
    super.key,
    required this.nameController,
    required this.phoneController,
  });

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, fontWeight: FontWeight.bold),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: nameController,
            label: AppStrings.customerName,
            hint: AppStrings.fullName,
            validator: (val) => AppValidator.validateOptional(
              val,
              (v) => AppValidator.validateMinLength(v, 2),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildTextField(
            controller: phoneController,
            label: AppStrings.phoneNumber,
            hint: AppStrings.hintPhoneNumber,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            ],
            validator: (val) => AppValidator.validateOptional(
              val,
              AppValidator.validatePhone,
            ),
          ),
        ),
      ],
    );
  }
}
