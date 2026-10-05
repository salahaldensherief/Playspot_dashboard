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
  final TextEditingController hourlyRateSingleController;
  final TextEditingController hourlyRateMultiController;
  final bool isOpenArea;

  const RoomBasicInfoForm({
    super.key,
    required this.nameArController,
    required this.nameEnController,
    required this.descriptionArController,
    required this.descriptionEnController,
    required this.hourlyRateSingleController,
    required this.hourlyRateMultiController,
    this.isOpenArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    final nameArField = AppTextField(
      label: isOpenArea
          ? AppStrings.stationNameLabelAr
          : AppStrings.roomNameLabelAr,
      hintText: isOpenArea
          ? AppStrings.stationNameLabelAr
          : AppStrings.roomNameLabelAr,
      controller: nameArController,
      validator: AppValidator.validateRequired,
    );

    final nameEnField = AppTextField(
      label: isOpenArea
          ? AppStrings.stationNameLabelEn
          : AppStrings.roomNameLabelEn,
      hintText: isOpenArea
          ? AppStrings.stationNameLabelEn
          : AppStrings.roomNameLabelEn,
      controller: nameEnController,
      validator: AppValidator.validateRequired,
    );

    final descArField = AppTextField(
      label: AppStrings.descriptionArLabel,
      hintText: AppStrings.descriptionArHint,
      controller: descriptionArController,
      maxLines: 3,
    );

    final descEnField = AppTextField(
      label: AppStrings.descriptionEnLabel,
      hintText: AppStrings.descriptionEnHint,
      controller: descriptionEnController,
      maxLines: 3,
    );

    final singleRateField = AppTextField(
      label: AppStrings.singleRateLabel,
      hintText: AppStrings.pricePerHourHint,
      controller: hourlyRateSingleController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: AppValidator.validateNumber,
    );

    final multiRateField = AppTextField(
      label: AppStrings.multiRateLabel,
      hintText: AppStrings.pricePerHourHint,
      controller: hourlyRateMultiController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: AppValidator.validateNumber,
    );

    if (isCompact) {
      return Column(
        children: [
          nameArField,
          SizedBox(height: 16.h),
          nameEnField,
          SizedBox(height: 16.h),
          descArField,
          SizedBox(height: 16.h),
          descEnField,
          SizedBox(height: 16.h),
          singleRateField,
          SizedBox(height: 16.h),
          multiRateField,
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: nameArField),
            SizedBox(width: 16.w),
            Expanded(child: nameEnField),
          ],
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(child: descArField),
            SizedBox(width: 16.w),
            Expanded(child: descEnField),
          ],
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(child: singleRateField),
            SizedBox(width: 16.w),
            Expanded(child: multiRateField),
          ],
        ),
      ],
    );
  }
}
