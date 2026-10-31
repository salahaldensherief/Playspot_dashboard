import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';

class LocationStep extends StatefulWidget {
  final TextEditingController cityController;
  final TextEditingController addressController;
  final void Function(double? lat, double? lng)? onCoordinatesDetected;
  final double? initialLatitude, initialLongitude;

  const LocationStep({
    super.key,
    required this.cityController,
    required this.addressController,
    this.onCoordinatesDetected,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  bool _isLoading = false;
  String? _statusMessage;
  double? _lat;
  double? _lng;
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLatitude;
    _lng = widget.initialLongitude;
    _latitude.text = _lat?.toString() ?? '';
    _longitude.text = _lng?.toString() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_lat == null || _lng == null)) _autoDetectLocation();
    });
  }

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  double? _coordinate(String text, double limit) {
    final value = double.tryParse(text.trim());
    return value != null && value.isFinite && value.abs() <= limit
        ? value
        : null;
  }

  void _manualChanged(String _) {
    _revision++;
    _lat = _coordinate(_latitude.text, 90);
    _lng = _coordinate(_longitude.text, 180);
    final valid = _lat != null && _lng != null;
    widget.onCoordinatesDetected?.call(
      valid ? _lat : null,
      valid ? _lng : null,
    );
    setState(
      () => _statusMessage = valid
          ? 'onboarding_location.manual_saved'
          : 'onboarding_location.invalid',
    );
  }

  Future<void> _autoDetectLocation() async {
    if (!mounted || _isLoading) return;
    final revision = _revision;
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final locationService = sl<LocationService>();
      final pos = await locationService.getCurrentPosition();
      if (!mounted || revision != _revision) return;

      if (pos != null && mounted) {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _latitude.text = pos.latitude.toString();
        _longitude.text = pos.longitude.toString();

        widget.onCoordinatesDetected?.call(pos.latitude, pos.longitude);

        final city = await locationService.getCityFromPosition(pos, context);
        if (!mounted || revision != _revision) return;
        if (widget.cityController.text.trim().isEmpty &&
            city != null &&
            city.trim().isNotEmpty) {
          widget.cityController.text = city.trim();
        }

        if (widget.onCoordinatesDetected != null) {
          widget.onCoordinatesDetected!(pos.latitude, pos.longitude);
        }

        setState(() {
          _statusMessage = 'onboarding_location.detected';
        });
      } else {
        setState(() {
          _statusMessage = 'onboarding_location.unavailable';
        });
      }
    } catch (e) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _statusMessage = 'onboarding_location.unavailable';
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
    EasyLocalization.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          fontSize: 16,
          label: AppStrings.city,
          hintText: AppStrings.cityHint,
          controller: widget.cityController,
        ),
        SizedBox(height: 20.h),
        AppTextField(
          fontSize: 16,
          label: AppStrings.address,
          hintText: AppStrings.addressHint,
          controller: widget.addressController,
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.mutedBackground.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  Text(
                    _lat != null && _lng != null
                        ? 'onboarding_location.coordinates'.tr(
                            namedArgs: {
                              'latitude': _lat?.toStringAsFixed(4) ?? '',
                              'longitude': _lng?.toStringAsFixed(4) ?? '',
                            },
                          )
                        : 'onboarding_location.title'.tr(),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppButton(
                    fontSize: 16,
                    text: 'onboarding_location.detect'.tr(),
                    icon: Icons.gps_fixed_rounded,
                    variant: AppButtonVariant.primary,
                    isLoading: _isLoading,
                    onPressed: _autoDetectLocation,
                  ),
                ],
              ),
              if (_statusMessage != null) ...[
                SizedBox(height: 10.h),
                Text(
                  _statusMessage?.tr() ?? '',
                  style: TextStyle(
                    color:
                        (_statusMessage == 'onboarding_location.detected' ||
                            _statusMessage ==
                                'onboarding_location.manual_saved')
                        ? AppColors.success
                        : AppColors.warning,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text('onboarding_location.help'.tr()),
              const SizedBox(height: 12),
              AppTextField(
                key: const ValueKey('venue-latitude'),
                label: 'onboarding_location.latitude'.tr(),
                controller: _latitude,
                onChanged: _manualChanged,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: const ValueKey('venue-longitude'),
                label: 'onboarding_location.longitude'.tr(),
                controller: _longitude,
                onChanged: _manualChanged,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
