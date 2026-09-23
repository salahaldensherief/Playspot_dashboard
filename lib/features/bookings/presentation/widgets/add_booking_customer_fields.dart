import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, fontWeight: FontWeight.bold),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
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
          validator: (val) => val == null || val.isEmpty ? AppStrings.fieldRequired : null,
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
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildTextField(
            controller: phoneController,
            label: AppStrings.phoneNumber,
            hint: "01xxxxxxxxx",
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }
}
