import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class RoomBasicInfoForm extends StatelessWidget {
  final TextEditingController nameArController;
  final TextEditingController nameEnController;
  final TextEditingController descriptionArController;
  final TextEditingController descriptionEnController;
  final TextEditingController priceSingleController;
  final TextEditingController priceMultiController;
  final TextEditingController pricePerHourController;
  final bool isOpenArea;

  const RoomBasicInfoForm({
    super.key,
    required this.nameArController,
    required this.nameEnController,
    required this.descriptionArController,
    required this.descriptionEnController,
    required this.priceSingleController,
    required this.priceMultiController,
    required this.pricePerHourController,
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
                label: AppStrings.descriptionArLabel,
                hintText: 'وصف الغرفة والمواصفات (مثل نوع الدركسيون في السيميليتور)...',
                controller: descriptionArController,
                maxLines: 3,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.descriptionEnLabel,
                hintText: 'Description & Specs (e.g. Wheel type for Simulators, PC specs)...',
                controller: descriptionEnController,
                maxLines: 3,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        if (isOpenArea)
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: AppStrings.singlePrice,
                  hintText: AppStrings.pricePerHourHint,
                  controller: priceSingleController,
                  keyboardType: TextInputType.number,
                  validator: AppValidator.validateNumber,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: AppTextField(
                  label: AppStrings.multiPrice,
                  hintText: AppStrings.pricePerHourHint,
                  controller: priceMultiController,
                  keyboardType: TextInputType.number,
                  validator: AppValidator.validateNumber,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: AppStrings.roomPricePerHour,
                  hintText: AppStrings.pricePerHourHint,
                  controller: pricePerHourController,
                  keyboardType: TextInputType.number,
                  validator: AppValidator.validateNumber,
                ),
              ),
              const Spacer(),
            ],
          ),
      ],
    );
  }
}
