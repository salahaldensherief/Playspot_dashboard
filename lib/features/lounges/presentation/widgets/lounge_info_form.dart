import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_image_picker.dart';
import 'dart:typed_data';

class LoungeInfoForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController cityController;
  final Function(Uint8List? bytes, String? name) onImageSelected;

  const LoungeInfoForm({
    super.key,
    required this.nameController,
    required this.cityController,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppImagePicker(
          label: AppStrings.loungeBannerImage,
          onImageSelected: onImageSelected,
        ),
        SizedBox(height: 20.h),
        AppTextField(
          label: AppStrings.loungeName,
          hintText: 'e.g. Nexus Gaming',
          controller: nameController,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        SizedBox(height: 20.h),
        AppTextField(
          label: AppStrings.city,
          hintText: 'e.g. Cairo',
          controller: cityController,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
