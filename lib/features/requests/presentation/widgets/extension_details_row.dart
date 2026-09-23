import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/notification_metadata.dart';

class ExtensionDetailsRow extends StatelessWidget {
  final NotificationMetadata metadata;

  const ExtensionDetailsRow({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final firstMetadataItem = metadata.items.isNotEmpty
        ? metadata.items.first
        : <String, dynamic>{};

    final int requestedMinutes = (firstMetadataItem['requested_minutes'] ??
            firstMetadataItem['minutes'] as num?)
        ?.toInt() ??
        30;

    final int currentDuration =
        (firstMetadataItem['current_duration'] as num?)?.toInt() ?? 60;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.mutedBackground,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 14.r, color: AppColors.neonBlue),
              SizedBox(width: 4.w),
              AppText.subHeading(
                '+$requestedMinutes ${AppStrings.minutesUnit}',
                fontSize: 12.sp,
                color: AppColors.neonBlue,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        AppText.body(
          '${AppStrings.remainingTime}: $currentDuration ${AppStrings.minutesUnit}',
          fontSize: 11.sp,
          color: AppColors.textMuted,
        ),
      ],
    );
  }
}
