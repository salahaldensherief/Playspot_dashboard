import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class RoomBasicInfoForm extends StatelessWidget {
  final TextEditingController nameArController;
  final TextEditingController nameEnController;
  final TextEditingController priceSingleController;
  final TextEditingController priceMultiController;
  final bool isOpenArea;

  const RoomBasicInfoForm({
    super.key,
    required this.nameArController,
    required this.nameEnController,
    required this.priceSingleController,
    required this.priceMultiController,
    this.isOpenArea = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: isOpenArea ? AppStrings.stationNameLabelAr : AppStrings.roomNameLabelAr,
                hintText: isOpenArea ? AppStrings.stationNameLabelAr : AppStrings.roomNameLabelAr,
                controller: nameArController,
                validator: AppValidator.validateRequired,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: isOpenArea ? AppStrings.stationNameLabelEn : AppStrings.roomNameLabelEn,
                hintText: isOpenArea ? AppStrings.stationNameLabelEn : AppStrings.roomNameLabelEn,
                controller: nameEnController,
                validator: AppValidator.validateRequired,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'سعر الساعة (فردي / Single)',
                hintText: AppStrings.pricePerHourHint,
                controller: priceSingleController,
                keyboardType: TextInputType.number,
                validator: AppValidator.validateNumber,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: 'سعر الساعة (زوجي / Multi)',
                hintText: AppStrings.pricePerHourHint,
                controller: priceMultiController,
                keyboardType: TextInputType.number,
                validator: AppValidator.validateNumber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
