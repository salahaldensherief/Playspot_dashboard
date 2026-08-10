import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/widgets/app_text_field.dart';

class LocationStep extends StatelessWidget {
  final TextEditingController cityController;
  final TextEditingController addressController;

  const LocationStep({
    super.key,
    required this.cityController,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: AppStrings.city,
          hintText: 'e.g. Cairo',
          controller: cityController,
        ),
        SizedBox(height: 20.h),
        AppTextField(
          label: AppStrings.address,
          hintText: 'Detailed address',
          controller: addressController,
        ),
      ],
    );
  }
}
