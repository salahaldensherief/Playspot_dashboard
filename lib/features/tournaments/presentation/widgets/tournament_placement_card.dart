import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../domain/entities/tournament_prize_entity.dart';
import '../../domain/entities/tournament_prize_reward_entity.dart';
import 'tournament_reward_row.dart';

class TournamentPlacementCard extends StatelessWidget {
  final TournamentPrizeEntity prize;
  final int placementIndex;
  final bool canDeletePlacement;
  final VoidCallback onAddReward;
  final VoidCallback onRemovePlacement;
  final void Function(int rewardIndex, TournamentPrizeRewardEntity updatedReward) onUpdateReward;
  final void Function(int rewardIndex) onRemoveReward;

  const TournamentPlacementCard({
    super.key,
    required this.prize,
    required this.placementIndex,
    required this.canDeletePlacement,
    required this.onAddReward,
    required this.onRemovePlacement,
    required this.onUpdateReward,
    required this.onRemoveReward,
  });

  String _getPlacementLabel(int placement) {
    switch (placement) {
      case 1:
        return '🥇 ${AppStrings.firstPlace}';
      case 2:
        return '🥈 ${AppStrings.secondPlace}';
      case 3:
        return '🥉 ${AppStrings.thirdPlace}';
      case 4:
        return '🎖️ ${AppStrings.fourthPlace}';
      default:
        return '🏆 ${AppStrings.placement} $placement';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getPlacementLabel(prize.placement),
                style: TextStyle(
                  color: AppColors.neonBlue,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  AppButton(
                    text: AppStrings.addPrizeReward,
                    icon: Icons.add,
                    variant: AppButtonVariant.outlined,
                    fontSize: 11.sp,
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    onPressed: onAddReward,
                  ),
                  if (canDeletePlacement) ...[
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                      tooltip: AppStrings.cancel,
                      onPressed: onRemovePlacement,
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (prize.rewards.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'لا يوجد جوائز محددة لهذا المركز',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prize.rewards.length,
              itemBuilder: (context, rewardIndex) {
                final reward = prize.rewards[rewardIndex];
                return TournamentRewardRow(
                  key: ValueKey(reward.id),
                  reward: reward,
                  placementIndex: placementIndex,
                  rewardIndex: rewardIndex,
                  canDelete: prize.rewards.length > 1,
                  onUpdate: (updated) => onUpdateReward(rewardIndex, updated),
                  onDelete: () => onRemoveReward(rewardIndex),
                );
              },
            ),
        ],
      ),
    );
  }
}
