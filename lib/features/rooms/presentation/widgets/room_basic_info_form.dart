import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

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
                hintText: 'مثال: غرفة VIP 1',
                controller: nameArController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.nameEn,
                hintText: 'e.g. VIP Room 01',
                controller: nameEnController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        AppTextField(
          label: AppStrings.pricePerHour,
          hintText: '0.00',
          controller: priceController,
          keyboardType: TextInputType.number,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
