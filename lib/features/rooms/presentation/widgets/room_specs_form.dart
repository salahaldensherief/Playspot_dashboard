import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

class RoomSpecsForm extends StatelessWidget {
  final TextEditingController capacityController;
  final TextEditingController controllersController;
  final TextEditingController screenSizeController;
  final TextEditingController extraPriceController;
  final String? selectedSpaceTypeId;
  final RoomStatusEnum status;
  final Function(RoomStatusEnum?)? onStatusChanged;
  final List<String> featuresEn;
  final Function(String, bool) onFeatureChanged;

  const RoomSpecsForm({
    super.key,
    required this.capacityController,
    required this.controllersController,
    required this.screenSizeController,
    required this.extraPriceController,
    this.selectedSpaceTypeId,
    required this.status,
    this.onStatusChanged,
    required this.featuresEn,
    required this.onFeatureChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOpenArea = selectedSpaceTypeId == 'open_area';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomDropdown<RoomStatusEnum>(
                label: AppStrings.status,
                value: status,
                items: RoomStatusEnum.values,
                itemLabel: (s) => s.name.toUpperCase(),
                onChanged: onStatusChanged!,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.extraControllerPrice,
                hintText: AppStrings.pricePerHourHint,
                controller: extraPriceController,
                keyboardType: TextInputType.number,
                validator: AppValidator.validateNumber,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: isOpenArea ? AppStrings.capacity : AppStrings.roomCapacityLabel,
                hintText: AppStrings.capacityHint,
                controller: capacityController,
                keyboardType: TextInputType.number,
                validator: AppValidator.validateNumber,
              ),
            ),
            SizedBox(width: 16.w),
            if (isOpenArea) ...[
              Expanded(
                child: AppTextField(
                  label: AppStrings.controllers,
                  hintText: AppStrings.controllersHint,
                  controller: controllersController,
                  keyboardType: TextInputType.number,
                  validator: AppValidator.validateOptionalNumber,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: AppTextField(
                  label: AppStrings.specs,
                  hintText: AppStrings.screenSizeHint,
                  controller: screenSizeController,
                ),
              ),
            ] else ...[
              const Spacer(flex: 2),
            ],
          ],
        ),
        if (!isOpenArea) ...[
          SizedBox(height: 24.h),
          Text(
            AppStrings.specs,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 24.w,
            runSpacing: 12.h,
            children: [
              _buildFeatureCheckbox(AppStrings.airConditioning, 'Air Conditioning'),
              _buildFeatureCheckbox(AppStrings.soundproof, 'Soundproof'),
              _buildFeatureCheckbox(AppStrings.soundSystem, 'Sound System'),
              _buildFeatureCheckbox(AppStrings.screen4k, '4K Screen'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFeatureCheckbox(String label, String value) {
    final isSelected = featuresEn.contains(value);
    return InkWell(
      onTap: () => onFeatureChanged(value, !isSelected),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (v) => onFeatureChanged(value, v ?? false),
            activeColor: AppColors.neonBlue,
          ),
          Text(
            label,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}
