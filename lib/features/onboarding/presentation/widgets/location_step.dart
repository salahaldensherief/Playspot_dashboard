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
  final Function(double lat, double lng)? onCoordinatesDetected;

  const LocationStep({
    super.key,
    required this.cityController,
    required this.addressController,
    this.onCoordinatesDetected,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  bool _isLoading = false;
  String? _statusMessage;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectLocation();
    });
  }

  Future<void> _autoDetectLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final locationService = sl<LocationService>();
      final pos = await locationService.getCurrentPosition();

      if (pos != null && mounted) {
        _lat = pos.latitude;
        _lng = pos.longitude;

        final city = await locationService.getCityFromPosition(pos, context);
        if (city != null && city.trim().isNotEmpty) {
          widget.cityController.text = city.trim();
        }

        if (widget.onCoordinatesDetected != null) {
          widget.onCoordinatesDetected!(pos.latitude, pos.longitude);
        }

        setState(() {
          _statusMessage = 'تم الكشف عن المدينة والموقع الجغرافي تلقائياً بنجاح';
        });
      } else {
        setState(() {
          _statusMessage = 'تعذر الوصول للموقع تلقائياً. يمكنك كتابة المدينة والعنوان يدوياً.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'تعذر الوصول للموقع تلقائياً. يمكنك كتابة المدينة والعنوان يدوياً.';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: AppStrings.city,
          hintText: AppStrings.cityHint,
          controller: widget.cityController,
        ),
        SizedBox(height: 20.h),
        AppTextField(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.my_location_rounded, color: AppColors.neonBlue, size: 20.r),
                      SizedBox(width: 8.w),
                      Text(
                        _lat != null && _lng != null
                            ? 'الإحداثيات: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                            : 'تحديد موقع الصالة الجغرافي (GPS)',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AppButton(
                    text: 'تحديد تلقائي',
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
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusMessage!.contains('بنجاح') ? AppColors.success : AppColors.warning,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
