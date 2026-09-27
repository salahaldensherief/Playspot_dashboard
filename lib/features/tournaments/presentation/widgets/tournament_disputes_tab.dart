import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/section_container.dart';
import '../../domain/entities/tournament_match_entity.dart';

class TournamentDisputesTab extends StatelessWidget {
  final List<TournamentMatchEntity> disputedMatches;
  final ValueChanged<TournamentMatchEntity> onResolveDispute;

  const TournamentDisputesTab({
    super.key,
    required this.disputedMatches,
    required this.onResolveDispute,
  });

  @override
  Widget build(BuildContext context) {
    if (disputedMatches.isEmpty) {
      return SectionContainer(
        title: AppStrings.disputesRoom,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                SizedBox(height: 12.h),
                Text(
                  AppStrings.disputesRoom,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: disputedMatches.length,
      itemBuilder: (context, index) {
        final m = disputedMatches[index];
        return Card(
          color: AppColors.danger.withAlpha(20),
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: const BorderSide(color: AppColors.danger),
          ),
          child: ListTile(
            title: Text(
              '${AppStrings.disputesRoom} #${m.matchNumber}',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
              ),
            ),
            subtitle: Text(
              '${m.player1Name ?? "P1"} vs ${m.player2Name ?? "P2"}\n${m.disputeReason ?? ""}',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
            ),
            trailing: AppButton(
              text: AppStrings.resolveDispute,
              backgroundColor: AppColors.danger,
              onPressed: () => onResolveDispute(m),
            ),
          ),
        );
      },
    );
  }
}
