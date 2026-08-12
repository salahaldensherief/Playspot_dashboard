import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_image_picker.dart';
import '../../../../art_core/widgets/app_text.dart';

class KycStep extends StatelessWidget {
  final Function(Uint8List? bytes, String? name) onIdCardSelected;
  final Function(Uint8List? bytes, String? name) onBusinessDocSelected;

  const KycStep({
    super.key,
    required this.onIdCardSelected,
    required this.onBusinessDocSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(AppStrings.verifyIdentity, fontSize: 18.sp),
        SizedBox(height: 8.h),
        AppText.body(AppStrings.kycSubtitle),
        SizedBox(height: 32.h),
        Row(
          children: [
            Expanded(
              child: AppImagePicker(
                label: AppStrings.idCardImage,
                onImageSelected: onIdCardSelected,
              ),
            ),
            SizedBox(width: 24.w),
            Expanded(
              child: AppImagePicker(
                label: AppStrings.businessDocImage,
                onImageSelected: onBusinessDocSelected,
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.neonBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.neonBlue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.neonBlue),
              SizedBox(width: 12.w),
              Expanded(
                child: AppText.body(
                  'Verification usually takes 24-48 hours. You can still set up your lounge while we review your documents.',
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
