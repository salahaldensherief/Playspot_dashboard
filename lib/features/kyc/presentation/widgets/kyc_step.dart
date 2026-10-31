import 'package:easy_localization/easy_localization.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/responsive/app_breakpoints.dart';
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
    EasyLocalization.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(AppStrings.verifyIdentity, fontSize: 18),
        SizedBox(height: 8.h),
        AppText.body(AppStrings.kycSubtitle, fontSize: 16),
        SizedBox(height: 32.h),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = AppBreakpoints.isMobileWidth(constraints.maxWidth)
                ? constraints.maxWidth
                : (constraints.maxWidth - 24) / 2;
            return Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: AppImagePicker(
                    fontSize: 16,
                    allowPdf: true,
                    height: 160,
                    label: AppStrings.idCardImage,
                    onImageSelected: onIdCardSelected,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: AppImagePicker(
                    fontSize: 16,
                    allowPdf: true,
                    height: 160,
                    label: AppStrings.businessDocImage,
                    onImageSelected: onBusinessDocSelected,
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.neonBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.neonBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.neonBlue),
              SizedBox(width: 12.w),
              Expanded(
                child: AppText.body(
                  'onboarding_review.kyc_notice'.tr(),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
