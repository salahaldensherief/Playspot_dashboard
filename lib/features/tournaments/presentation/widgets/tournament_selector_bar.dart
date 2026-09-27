import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../domain/entities/tournament_entity.dart';
import 'tournament_status_badge.dart';

class TournamentSelectorBar extends StatelessWidget {
  final List<TournamentEntity> tournaments;
  final TournamentEntity? selected;
  final ValueChanged<TournamentEntity> onSelect;
  final VoidCallback onManagePrizes;
  final VoidCallback onPublish;
  final VoidCallback onDeleteDraft;
  final VoidCallback onCancel;
  final VoidCallback onAwardPrizes;

  const TournamentSelectorBar({
    super.key,
    required this.tournaments,
    required this.selected,
    required this.onSelect,
    required this.onManagePrizes,
    required this.onPublish,
    required this.onDeleteDraft,
    required this.onCancel,
    required this.onAwardPrizes,
  });

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Text(
            '${AppStrings.tournaments}: ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected?.id,
                dropdownColor: AppColors.cardBackground,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                items: tournaments.map((t) {
                  return DropdownMenuItem(
                    value: t.id,
                    child: Text(
                      '${t.title} (${t.gameTitle ?? "eSports"}) - ${t.registeredCount}/${t.maxPlayers}',
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  final found = tournaments.where((t) => t.id == id).firstOrNull;
                  if (found != null) {
                    onSelect(found);
                  }
                },
              ),
            ),
          ),
          if (selected != null) ...[
            TournamentStatusBadge(status: selected!.status),
            SizedBox(width: 8.w),
            AppButton(
              text: AppStrings.managePrizes,
              icon: Icons.emoji_events_outlined,
              variant: AppButtonVariant.outlined,
              fontSize: 12.sp,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              onPressed: onManagePrizes,
            ),
            SizedBox(width: 8.w),
            if (selected!.isDraft) ...[
              AppButton(
                text: AppStrings.publishTournament,
                backgroundColor: AppColors.success,
                fontSize: 12.sp,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                onPressed: onPublish,
              ),
              SizedBox(width: 8.w),
              if (selected!.registeredCount == 0)
                AppButton(
                  text: AppStrings.deleteDraft,
                  variant: AppButtonVariant.danger,
                  fontSize: 12.sp,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  onPressed: onDeleteDraft,
                )
              else
                AppButton(
                  text: AppStrings.cancelTournament,
                  variant: AppButtonVariant.danger,
                  fontSize: 12.sp,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  onPressed: onCancel,
                ),
            ] else if (!selected!.isCancelled) ...[
              AppButton(
                text: AppStrings.cancelTournament,
                variant: AppButtonVariant.danger,
                fontSize: 12.sp,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                onPressed: onCancel,
              ),
              if (selected!.isInProgress) ...[
                SizedBox(width: 8.w),
                AppButton(
                  text: AppStrings.completeBooking,
                  backgroundColor: AppColors.neonBlue,
                  fontSize: 12.sp,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  onPressed: onAwardPrizes,
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
