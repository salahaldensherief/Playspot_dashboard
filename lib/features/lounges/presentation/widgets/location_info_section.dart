import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/responsive/app_breakpoints.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

class LocationInfoSection extends StatefulWidget {
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
  State<LocationInfoSection> createState() => _LocationInfoSectionState();
}

class _LocationInfoSectionState extends State<LocationInfoSection> {
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _autoDetectLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final locationService = sl<LocationService>();
      final pos = await locationService.getCurrentPosition();

      if (pos != null && mounted) {
        final city = await locationService.getCityFromPosition(pos, context);
        if (city != null && city.trim().isNotEmpty) {
          widget.cityController.text = city.trim();
        }

        if (widget.onLocationChanged != null) {
          widget.onLocationChanged!(pos.latitude, pos.longitude);
        }

        setState(() {
          _statusMessage = 'تم الكشف عن الموقع والمدينة تلقائياً بنجاح';
        });
      } else {
        setState(() {
          _statusMessage =
              'تعذر تحديد الموقع تلقائياً من المتصفح. يمكنك إدخال البيانات يدوياً.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage =
            'تعذر تحديد الموقع تلقائياً من المتصفح. يمكنك إدخال البيانات يدوياً.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = AppBreakpoints.isMobile(context);

    final cityField = AppTextField(
      label: AppStrings.city,
      controller: widget.cityController,
      hintText: AppStrings.cityHint,
      validator: AppValidator.validateRequired,
    );

    final addressField = AppTextField(
      label: AppStrings.address,
      controller: widget.addressController,
      hintText: AppStrings.addressHint,
      validator: AppValidator.validateRequired,
    );

    final String latLngText = (widget.lat != null && widget.lng != null)
        ? '${widget.lat?.toStringAsFixed(4) ?? ''}, ${widget.lng?.toStringAsFixed(4) ?? ''}'
        : AppStrings.addressHint;

    final locationCoordinatesBox = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.neonBlue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              latLngText,
              style: const TextStyle(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final autoDetectButton = AppButton(
      text: AppStrings.updateMyLocation,
      icon: Icons.my_location_rounded,
      variant: AppButtonVariant.primary,
      isLoading: _isLoading,
      onPressed: _autoDetectLocation,
    );

    return SectionContainer(
      title: AppStrings.location,
      children: [
        if (isCompact) ...[
          cityField,
          const SizedBox(height: 16),
          addressField,
        ] else ...[
          Row(
            children: [
              Expanded(child: cityField),
              const SizedBox(width: 16),
              Expanded(child: addressField),
            ],
          ),
        ],
        const SizedBox(height: 24),
        if (isCompact)
          Column(
            children: [
              locationCoordinatesBox,
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: autoDetectButton),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: locationCoordinatesBox),
              const SizedBox(width: 12),
              autoDetectButton,
            ],
          ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _statusMessage ?? '',
            style: TextStyle(
              color: (_statusMessage?.contains('بنجاح') ?? false)
                  ? AppColors.success
                  : AppColors.warning,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
