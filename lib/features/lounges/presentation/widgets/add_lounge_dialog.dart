import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/map_location_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_image_picker.dart';

class AddLoungeDialog extends StatefulWidget {
  const AddLoungeDialog({super.key});

  @override
  State<AddLoungeDialog> createState() => _AddLoungeDialogState();
}

class _AddLoungeDialogState extends State<AddLoungeDialog> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  LatLng? _selectedLocation;
  Uint8List? _loungeImageBytes;
  String? _loungeImageName;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 1000.w,
        padding: EdgeInsets.all(32.r),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.loungeSetup,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        AppImagePicker(
                          label: AppStrings.loungeBannerImage,
                          onImageSelected: (bytes, name) {
                            _loungeImageBytes = bytes;
                            _loungeImageName = name;
                          },
                        ),
                        SizedBox(height: 20.h),
                        AppTextField(
                          label: AppStrings.loungeName,
                          hintText: 'e.g. Nexus Gaming',
                          controller: _nameController,
                        ),
                        SizedBox(height: 20.h),
                        AppTextField(
                          label: AppStrings.city,
                          hintText: 'e.g. Cairo',
                          controller: _cityController,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 32.w),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.pinLocationMap,
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp),
                        ),
                        SizedBox(height: 12.h),
                        MapLocationPicker(
                          onLocationSelected: (location) {
                            setState(() {
                              _selectedLocation = location;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              const Divider(color: AppColors.divider),
              SizedBox(height: 32.h),
              Text(
                AppStrings.loungeOwnerAdmin,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.ownerName,
                      hintText: AppStrings.ownerNameHint,
                      controller: _ownerNameController,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.ownerEmail,
                      hintText: AppStrings.ownerEmailHint,
                      controller: _ownerEmailController,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.ownerPassword,
                      hintText: AppStrings.passwordHint,
                      controller: _ownerPasswordController,
                      isPassword: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: AppStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 16.w),
                  AppButton(
                    text: AppStrings.createLoungeAdmin,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
