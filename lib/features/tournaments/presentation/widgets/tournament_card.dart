import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../domain/entities/tournament_entity.dart';
import 'tournament_status_badge.dart';

class TournamentCard extends StatelessWidget {
  final TournamentEntity tournament;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onManagePrizes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.isSelected,
    required this.onSelect,
    required this.onManagePrizes,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    return Card(
      color: isSelected ? AppColors.neonBlue.withAlpha(15) : AppColors.cardBackground,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(color: isSelected ? AppColors.neonBlue : AppColors.borderDefault),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.r),
        title: Row(
          children: [
            Text(
              t.title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(width: 12.w),
            TournamentStatusBadge(status: t.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6.h),
            Text(
              '${AppStrings.gameTitle}: ${t.gameTitle ?? "eSports"} | ${AppStrings.entryFee}: ${t.entryFee} | ${AppStrings.prizePool}: ${t.prizePool}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              '${AppStrings.maxPlayers}: ${t.registeredCount} / ${t.maxPlayers} (${AppStrings.treeSize}: ${t.treeSize})',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
            ),
            if (t.prizes.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: t.prizes.map((p) {
                  final rewardsSummary = p.rewards.map((r) {
                    final icon = r.isTrophy
                        ? '🏆'
                        : r.isCash
                            ? '💵 ${r.value ?? ""} ${r.currency ?? "EGP"}'
                            : r.isPoints
                                ? '⭐ ${r.value ?? ""} pts'
                                : r.isVoucher
                                    ? '🎟️ ${r.value ?? ""}%'
                                    : '🎁';
                    final title = r.titleAr ?? r.title ?? icon;
                    return '$title ($icon)';
                  }).join(' + ');

                  final placementLabel = p.placement == 1
                      ? '🥇'
                      : p.placement == 2
                          ? '🥈'
                          : p.placement == 3
                              ? '🥉'
                              : '#${p.placement}';

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.mutedBackground,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: AppColors.borderDefault.withAlpha(80)),
                    ),
                    child: Text(
                      '$placementLabel $rewardsSummary',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              text: AppStrings.managePrizes,
              icon: Icons.emoji_events_outlined,
              variant: AppButtonVariant.outlined,
              fontSize: 12.sp,
              onPressed: onManagePrizes,
            ),
            SizedBox(width: 8.w),
            AppButton(
              text: AppStrings.edit,
              variant: AppButtonVariant.outlined,
              fontSize: 12.sp,
              onPressed: onEdit,
            ),
            SizedBox(width: 8.w),
            AppButton(
              text: AppStrings.deleteTournament,
              variant: AppButtonVariant.danger,
              fontSize: 12.sp,
              onPressed: onDelete,
            ),
            SizedBox(width: 8.w),
            AppButton(
              text: AppStrings.viewAll,
              fontSize: 12.sp,
              onPressed: onSelect,
            ),
          ],
        ),
      ),
    );
  }
}
