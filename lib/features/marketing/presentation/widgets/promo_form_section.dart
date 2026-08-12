import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class PromoFormSection extends StatelessWidget {
  final String selectedDeepLink;
  final Function(String?) onDeepLinkChanged;

  const PromoFormSection({
    super.key,
    required this.selectedDeepLink,
    required this.onDeepLinkChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: AppStrings.promotionsMarketing,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.promoTitleAr,
                hintText: AppStrings.promoTitleArHint,
                validator: AppValidator.validateRequired,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                label: AppStrings.promoTitleEn,
                hintText: AppStrings.promoTitleEnHint,
                validator: AppValidator.validateRequired,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.tagAr,
                hintText: AppStrings.tagArHint,
                validator: AppValidator.validateRequired,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                label: AppStrings.tagEn,
                hintText: AppStrings.tagEnHint,
                validator: AppValidator.validateRequired,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomDropdown<String>(
          label: AppStrings.deepLinkDest,
          value: selectedDeepLink,
          items: const ['Specific Room', 'Lounge Profile', 'External Link'],
          itemLabel: (s) => s,
          onChanged: onDeepLinkChanged,
        ),
      ],
    );
  }
}
