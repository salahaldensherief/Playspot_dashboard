import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/widgets/app_text_field.dart';

import 'dart:typed_data';
import 'package:play_spot_dashboard/art_core/widgets/app_image_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';

class BasicInfoStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController nameEnController;
  final TextEditingController descriptionController;
  final TextEditingController descriptionEnController;
  final TextEditingController contactPhoneController;
  final String? initialMainImageUrl;
  final Function(Uint8List? bytes, String? name) onMainImageSelected;
  final Function(List<SelectedImage> images) onGallerySelected;

  const BasicInfoStep({
    super.key,
    required this.nameController,
    required this.nameEnController,
    required this.descriptionController,
    required this.descriptionEnController,
    required this.contactPhoneController,
    this.initialMainImageUrl,
    required this.onMainImageSelected,
    required this.onGallerySelected,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
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
          label: AppStrings.nameAr,
          controller: nameController,
          textLanguage: TextFieldLanguage.arabic,
        ),
        SizedBox(height: 20.h),
        AppTextField(
          fontSize: 16,
          label: AppStrings.nameEn,
          controller: nameEnController,
          textLanguage: TextFieldLanguage.english,
        ),
        SizedBox(height: 20.h),
        AppTextField(
          fontSize: 16,
          label: AppStrings.descriptionArLabel,
          controller: descriptionController,
          textLanguage: TextFieldLanguage.arabic,
        ),
        SizedBox(height: 20.h),
        AppTextField(
          fontSize: 16,
          label: AppStrings.descriptionEnLabel,
          controller: descriptionEnController,
          textLanguage: TextFieldLanguage.english,
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
