import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

class LiveRequestsEmptyState extends StatelessWidget {
  const LiveRequestsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 36.r, color: AppColors.textMuted),
            SizedBox(height: 8.h),
            AppText.body(
              AppStrings.noActiveRequests,
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
          ],
        ),
      ),
    );
  }
}
