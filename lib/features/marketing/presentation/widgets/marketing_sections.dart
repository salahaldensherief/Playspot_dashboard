import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
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
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.promoTitleEn,
                hintText: AppStrings.promoTitleEnHint,
                validator: AppValidator.validateRequired,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.tagAr,
                hintText: AppStrings.tagArHint,
                validator: AppValidator.validateRequired,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.tagEn,
                hintText: AppStrings.tagEnHint,
                validator: AppValidator.validateRequired,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
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

class DesignStyleSection extends StatelessWidget {
  final List<List<Color>> colorTemplates;
  final int selectedTemplate;
  final Function(int) onTemplateSelected;
  final String selectedIcon;
  final Function(String?) onIconChanged;

  const DesignStyleSection({
    super.key,
    required this.colorTemplates,
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.selectedIcon,
    required this.onIconChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: AppStrings.designStyle,
      children: [
        Text(AppStrings.colorTemplate, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp)),
        SizedBox(height: 12.h),
        Row(
          children: List.generate(colorTemplates.length, (index) {
            return GestureDetector(
              onTap: () => onTemplateSelected(index),
              child: Container(
                margin: EdgeInsets.only(right: 12.w),
                width: 50.r,
                height: 50.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colorTemplates[index]),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedTemplate == index ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 24.h),
        CustomDropdown<String>(
          label: AppStrings.promoIcon,
          value: selectedIcon,
          items: const ['Flash', 'Star', 'Gift', 'Hot'],
          itemLabel: (s) => s,
          onChanged: onIconChanged,
        ),
      ],
    );
  }
}
