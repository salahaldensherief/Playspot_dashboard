import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/widgets/app_text_field.dart';

import 'dart:typed_data';
import 'package:play_spot_dashboard/art_core/widgets/app_image_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';

class BasicInfoStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController contactPhoneController;
  final String? initialMainImageUrl;
  final Function(Uint8List? bytes, String? name) onMainImageSelected;
  final Function(List<SelectedImage> images) onGallerySelected;

  const BasicInfoStep({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.contactPhoneController,
    this.initialMainImageUrl,
    required this.onMainImageSelected,
    required this.onGallerySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppImagePicker(
          fontSize: 16,
          height: 180,
          initialImageUrl: initialMainImageUrl,
          label: AppStrings.mainImage,
          onImageSelected: onMainImageSelected,
        ),
        SizedBox(height: 20.h),
        AppTextField(
          fontSize: 16,
          label: AppStrings.loungeName,
          hintText: AppStrings.loungeNameHint,
          controller: nameController,
        ),
        SizedBox(height: 20.h),
        AppTextField(
          fontSize: 16,
          label: AppStrings.description,
          hintText: AppStrings.descriptionHint,
          controller: descriptionController,
        ),
        SizedBox(height: 20.h),
        AppTextField(
          fontSize: 16,
          label: AppStrings.phoneNumber,
          controller: contactPhoneController,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 24.h),
        AppMultiImagePicker(
          label: AppStrings.galleryImages,
          onImagesSelected: onGallerySelected,
        ),
      ],
    );
  }
}
