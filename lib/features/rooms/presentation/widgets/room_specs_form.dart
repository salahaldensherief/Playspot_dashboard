import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class RoomSpecsForm extends StatelessWidget {
  final TextEditingController capacityController;
  final TextEditingController controllersController;
  final TextEditingController screenSizeController;
  final String? selectedSpaceType;
  final Function(String?)? onSpaceTypeChanged;

  const RoomSpecsForm({
    super.key,
    required this.capacityController,
    required this.controllersController,
    required this.screenSizeController,
    this.selectedSpaceType,
    this.onSpaceTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomDropdown<String>(
                label: 'Space Type',
                value: selectedSpaceType ?? 'Private',
                items: const ['Private', 'Shared', 'Area'],
                itemLabel: (s) => s,
                onChanged: onSpaceTypeChanged!,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.capacity,
                hintText: AppStrings.capacityHint,
                controller: capacityController,
                keyboardType: TextInputType.number,
                validator: AppValidator.validateNumber,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.controllers,
                hintText: AppStrings.controllersHint,
                controller: controllersController,
                keyboardType: TextInputType.number,
                validator: AppValidator.validateOptionalNumber,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        AppTextField(
          label: AppStrings.specs,
          hintText: AppStrings.screenSizeHint,
          controller: screenSizeController,
        ),
      ],
    );
  }
}
