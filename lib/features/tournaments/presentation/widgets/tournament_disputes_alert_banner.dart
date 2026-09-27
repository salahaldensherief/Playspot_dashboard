import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';

class TournamentDisputesAlertBanner extends StatelessWidget {
  final int disputedCount;
  final String player1Name;
  final String player2Name;
  final VoidCallback onResolve;

  const TournamentDisputesAlertBanner({
    super.key,
    required this.disputedCount,
    required this.player1Name,
    required this.player2Name,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    if (disputedCount <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.danger.withAlpha(25),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.danger, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.disputesRoom}: $disputedCount ${AppStrings.pendingRequests}',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${AppStrings.resolveDispute} $player1Name vs $player2Name',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
                ),
              ],
            ),
          ),
          AppButton(
            text: AppStrings.resolveDispute,
            backgroundColor: AppColors.danger,
            onPressed: onResolve,
          ),
        ],
      ),
    );
  }
}
