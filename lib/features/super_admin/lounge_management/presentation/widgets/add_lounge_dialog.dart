import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/map_location_picker.dart';

class AddLoungeDialog extends StatefulWidget {
  const AddLoungeDialog({super.key});

  @override
  State<AddLoungeDialog> createState() => _AddLoungeDialogState();
}

class _AddLoungeDialogState extends State<AddLoungeDialog> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 800.w,
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
                    'Setup New Lounge',
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
                        AppTextField(
                          label: 'Lounge Name',
                          hintText: 'e.g. Nexus Gaming',
                          controller: _nameController,
                        ),
                        SizedBox(height: 20.h),
                        AppTextField(
                          label: 'City',
                          hintText: 'e.g. Cairo',
                          controller: _cityController,
                        ),
                        SizedBox(height: 20.h),
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: AppColors.mutedBackground,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pro Tip:',
                                style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, fontSize: 12.sp),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Accurate coordinates allow users to find your lounge via GPS proximity in the mobile app.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
                              ),
                            ],
                          ),
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
                          'Pin Location on Map',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                      side: const BorderSide(color: AppColors.borderDefault),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary)),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: () {
                      // Logic to save to Supabase using LoungeRepository
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonBlue,
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                    ),
                    child: const Text('Create Lounge', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
