import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';

class TournamentPrizeBanner extends StatelessWidget {
  final int prizeCount;
  final VoidCallback onManagePrizes;

  const TournamentPrizeBanner({
    super.key,
    required this.prizeCount,
    required this.onManagePrizes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tournamentPrizes,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                prizeCount == 0
                    ? 'لم يتم تخصيص جوائز للمراكز بعد'
                    : 'تم تخصيص $prizeCount مراكز للجوائز',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          AppButton(
            text: AppStrings.managePrizes,
            icon: Icons.emoji_events_outlined,
            variant: AppButtonVariant.outlined,
            fontSize: 12.sp,
            onPressed: onManagePrizes,
          ),
        ],
      ),
    );
  }
}
