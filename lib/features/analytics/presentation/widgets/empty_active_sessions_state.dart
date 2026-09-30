import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';

class EmptyActiveSessionsState extends StatelessWidget {
  const EmptyActiveSessionsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 40.r,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 8.h),
            AppText.body(
              AppStrings.noActiveSessions,
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
          ],
        ),
      ),
    );
  }
}
