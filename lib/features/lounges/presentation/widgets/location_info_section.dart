import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class LocationInfoSection extends StatelessWidget {
  final TextEditingController cityController;
  final TextEditingController addressController;
  final double? lat;
  final double? lng;
  final Function(double lat, double lng)? onLocationChanged;

  const LocationInfoSection({
    super.key,
    required this.cityController,
    required this.addressController,
    this.lat,
    this.lng,
    this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: AppStrings.location, 
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
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.neonBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    lat != null && lng != null 
                        ? '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'
                        : AppStrings.addressHint,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            AppButton(
              text: AppStrings.pinLocationMap,
              icon: Icons.gps_fixed,
              variant: AppButtonVariant.outlined,
              onPressed: () async {
                final pos = await sl<LocationService>().getCurrentPosition();
                if (pos != null && onLocationChanged != null) {
                  onLocationChanged!(pos.latitude, pos.longitude);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
