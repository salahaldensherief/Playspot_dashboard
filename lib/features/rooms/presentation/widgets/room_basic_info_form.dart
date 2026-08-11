import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class RoomBasicInfoForm extends StatelessWidget {
  final TextEditingController nameArController;
  final TextEditingController nameEnController;
  final TextEditingController priceController;

  const RoomBasicInfoForm({
    super.key,
    required this.nameArController,
    required this.nameEnController,
    required this.priceController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.nameAr,
                hintText: AppStrings.nameAr,
                controller: nameArController,
                validator: AppValidator.validateRequired,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.nameEn,
                hintText: AppStrings.nameEn,
                controller: nameEnController,
                validator: AppValidator.validateRequired,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        AppTextField(
          label: AppStrings.pricePerHour,
          hintText: AppStrings.pricePerHourHint,
          controller: priceController,
          keyboardType: TextInputType.number,
          validator: AppValidator.validateNumber,
        ),
      ],
    );
  }
}
