import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

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
            const SizedBox(width: 16),
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
