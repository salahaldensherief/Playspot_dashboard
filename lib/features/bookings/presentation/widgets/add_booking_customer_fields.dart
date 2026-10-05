import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

class AddBookingCustomerFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  const AddBookingCustomerFields({
    super.key,
    required this.nameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final name = AppTextField(
          controller: nameController,
          label: AppStrings.customerName,
          hintText: AppStrings.fullName,
        );
        final phone = AppTextField(
          controller: phoneController,
          label: AppStrings.phoneNumber,
          hintText: AppStrings.hintPhoneNumber,
          keyboardType: TextInputType.phone,
        );
        if (constraints.maxWidth <
            480 * MediaQuery.textScalerOf(context).scale(1)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [name, SizedBox(height: 16.h), phone],
          );
        }
        return Row(
          children: [
            Expanded(child: name),
            SizedBox(width: 16.w),
            Expanded(child: phone),
          ],
        );
      },
    );
  }
}
