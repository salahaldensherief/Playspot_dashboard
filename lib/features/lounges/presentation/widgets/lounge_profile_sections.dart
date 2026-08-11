import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_image_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'dart:typed_data';

class CoreInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descArController;
  final TextEditingController descEnController;
  final Function(Uint8List? bytes, String? name) onMainImageSelected;
  final Function(List<SelectedImage> images) onGallerySelected;

  const CoreInfoSection({
    super.key,
    required this.nameController,
    required this.descArController,
    required this.descEnController,
    required this.onMainImageSelected,
    required this.onGallerySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: AppStrings.coreInfo,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: AppImagePicker(
                label: AppStrings.mainImage,
                onImageSelected: onMainImageSelected,
              ),
            ),
            SizedBox(width: 24.w),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  AppTextField(
                    label: AppStrings.loungeName,
                    controller: nameController,
                    hintText: AppStrings.loungeNameHint,
                    validator: AppValidator.validateRequired,
                  ),
                  SizedBox(height: 16.h),
                  AppTextField(
                    label: AppStrings.descriptionArLabel,
                    controller: descArController,
                    hintText: AppStrings.descriptionArHint,
                  ),
                  SizedBox(height: 16.h),
                  AppTextField(
                    label: AppStrings.descriptionEnLabel,
                    controller: descEnController,
                    hintText: AppStrings.descriptionEnHint,
                  ),
                ],
              ),
            ),
          ],
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

class LocationInfoSection extends StatelessWidget {
  final TextEditingController cityController;
  final TextEditingController addressController;

  const LocationInfoSection({
    super.key,
    required this.cityController,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Location Info', 
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.city,
                controller: cityController,
                hintText: AppStrings.cityHint,
                validator: AppValidator.validateRequired,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.address,
                controller: addressController,
                hintText: AppStrings.addressHint,
                validator: AppValidator.validateRequired,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class WorkingHoursSection extends StatelessWidget {
  final TextEditingController opensAtController;
  final TextEditingController closesAtController;
  final VoidCallback onOpensAtTap;
  final VoidCallback onClosesAtTap;

  const WorkingHoursSection({
    super.key,
    required this.opensAtController,
    required this.closesAtController,
    required this.onOpensAtTap,
    required this.onClosesAtTap,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Working Hours',
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.opensAt,
                controller: opensAtController,
                hintText: '10:00 AM',
                prefixIcon: Icons.access_time,
                readOnly: true,
                onTap: onOpensAtTap,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.closesAt,
                controller: closesAtController,
                hintText: '02:00 AM',
                prefixIcon: Icons.access_time,
                readOnly: true,
                onTap: onClosesAtTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
