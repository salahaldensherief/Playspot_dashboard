import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../domain/entities/tournament_prize_reward_entity.dart';

class TournamentRewardRow extends StatelessWidget {
  final TournamentPrizeRewardEntity reward;
  final int placementIndex;
  final int rewardIndex;
  final bool canDelete;
  final ValueChanged<TournamentPrizeRewardEntity> onUpdate;
  final VoidCallback onDelete;

  const TournamentRewardRow({
    super.key,
    required this.reward,
    required this.placementIndex,
    required this.rewardIndex,
    required this.canDelete,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderDefault.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.prizeType,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
                    ),
                    SizedBox(height: 4.h),
                    DropdownButtonFormField<TournamentPrizeType>(
                      initialValue: reward.type,
                      dropdownColor: AppColors.cardBackground,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: AppColors.borderDefault),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: TournamentPrizeType.trophy,
                          child: Text('🏆 ${AppStrings.prizeTrophy}'),
                        ),
                        DropdownMenuItem(
                          value: TournamentPrizeType.cash,
                          child: Text('💵 ${AppStrings.prizeCash}'),
                        ),
                        DropdownMenuItem(
                          value: TournamentPrizeType.points,
                          child: Text('⭐ ${AppStrings.prizePoints}'),
                        ),
                        DropdownMenuItem(
                          value: TournamentPrizeType.voucher,
                          child: Text('🎟️ ${AppStrings.prizeVoucher}'),
                        ),
                        DropdownMenuItem(
                          value: TournamentPrizeType.custom,
                          child: Text('🎁 ${AppStrings.prizeCustom}'),
                        ),
                      ],
                      onChanged: (newType) {
                        if (newType != null) {
                          onUpdate(reward.copyWith(type: newType));
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 3,
                child: AppTextField(
                  initialValue: reward.titleAr ?? reward.title ?? '',
                  label: AppStrings.titleAr,
                  onChanged: (val) {
                    onUpdate(reward.copyWith(titleAr: val, title: val));
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 3,
                child: AppTextField(
                  initialValue: reward.titleEn ?? '',
                  label: AppStrings.titleEn,
                  onChanged: (val) {
                    onUpdate(reward.copyWith(titleEn: val));
                  },
                ),
              ),
              if (canDelete) ...[
                SizedBox(width: 8.w),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.danger, size: 20),
                  tooltip: AppStrings.cancel,
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              if (reward.isCash || reward.isPoints || reward.isVoucher) ...[
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    initialValue: reward.value != null ? reward.value.toString() : '',
                    label: reward.isCash
                        ? '${AppStrings.prizeValue} (${reward.currency ?? "EGP"})'
                        : reward.isPoints
                            ? 'عدد النقاط'
                            : 'نسبة الخصم / القيمة',
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = double.tryParse(val.trim());
                      onUpdate(reward.copyWith(value: parsed));
                    },
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              if (reward.isCash) ...[
                Expanded(
                  flex: 1,
                  child: AppTextField(
                    initialValue: reward.currency ?? 'EGP',
                    label: AppStrings.currency,
                    onChanged: (val) {
                      onUpdate(reward.copyWith(currency: val));
                    },
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                flex: 3,
                child: AppTextField(
                  initialValue: reward.descriptionAr ?? reward.description ?? '',
                  label: AppStrings.descriptionAr,
                  onChanged: (val) {
                    onUpdate(reward.copyWith(descriptionAr: val, description: val));
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 3,
                child: AppTextField(
                  initialValue: reward.descriptionEn ?? '',
                  label: AppStrings.descriptionEn,
                  onChanged: (val) {
                    onUpdate(reward.copyWith(descriptionEn: val));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
