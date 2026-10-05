import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_image_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

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
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    final imagePickerWidget = AppImagePicker(
      label: AppStrings.mainImage,
      onImageSelected: onMainImageSelected,
    );

    final fieldsWidget = Column(
      children: [
        AppTextField(
          label: AppStrings.loungeName,
          controller: nameController,
          hintText: AppStrings.loungeNameHint,
          validator: AppValidator.validateRequired,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: AppStrings.descriptionArLabel,
          controller: descArController,
          hintText: AppStrings.descriptionArHint,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: AppStrings.descriptionEnLabel,
          controller: descEnController,
          hintText: AppStrings.descriptionEnHint,
        ),
      ],
    );

    return SectionContainer(
      title: AppStrings.coreInfo,
      children: [
        if (isCompact) ...[
          imagePickerWidget,
          const SizedBox(height: 20),
          fieldsWidget,
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: imagePickerWidget),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: fieldsWidget),
            ],
          ),
        ],
        const SizedBox(height: 24),
        AppMultiImagePicker(
          label: AppStrings.galleryImages,
          onImagesSelected: onGallerySelected,
        ),
      ],
    );
  }
}
