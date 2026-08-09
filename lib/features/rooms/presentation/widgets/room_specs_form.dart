import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

class RoomSpecsForm extends StatelessWidget {
  final TextEditingController capacityController;
  final TextEditingController controllersController;
  final TextEditingController screenSizeController;

  const RoomSpecsForm({
    super.key,
    required this.capacityController,
    required this.controllersController,
    required this.screenSizeController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.capacity,
                hintText: 'Persons',
                controller: capacityController,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.controllers,
                hintText: 'e.g. 2',
                controller: controllersController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        AppTextField(
          label: AppStrings.specs,
          hintText: 'e.g. 55"',
          controller: screenSizeController,
        ),
      ],
    );
  }
}
