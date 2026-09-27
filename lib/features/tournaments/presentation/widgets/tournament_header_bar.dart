import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../core/responsive/app_breakpoints.dart';

class TournamentHeaderBar extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const TournamentHeaderBar({
    super.key,
    required this.onRefresh,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.tournamentsHub,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            AppStrings.tournamentsHubSub,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: AppStrings.refresh,
                  variant: AppButtonVariant.outlined,
                  icon: Icons.refresh,
                  onPressed: onRefresh,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: AppButton(
                  text: AppStrings.createTournament,
                  icon: Icons.add,
                  onPressed: onCreate,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tournamentsHub,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                AppStrings.tournamentsHubSub,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Row(
          children: [
            AppButton(
              text: AppStrings.refresh,
              variant: AppButtonVariant.outlined,
              icon: Icons.refresh,
              onPressed: onRefresh,
            ),
            SizedBox(width: 12.w),
            AppButton(
              text: AppStrings.createTournament,
              icon: Icons.add,
              onPressed: onCreate,
            ),
          ],
        ),
      ],
    );
  }
}
