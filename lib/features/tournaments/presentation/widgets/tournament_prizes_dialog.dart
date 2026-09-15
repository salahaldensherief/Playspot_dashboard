import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_prize_entity.dart';
import '../../domain/entities/tournament_prize_reward_entity.dart';

class TournamentPrizesDialog extends StatefulWidget {
  final TournamentEntity tournament;
  final Function(List<TournamentPrizeEntity>) onSave;

  const TournamentPrizesDialog({
    super.key,
    required this.tournament,
    required this.onSave,
  });

  @override
  State<TournamentPrizesDialog> createState() => _TournamentPrizesDialogState();
}

class _TournamentPrizesDialogState extends State<TournamentPrizesDialog> {
  final _formKey = GlobalKey<FormState>();
  late List<TournamentPrizeEntity> _prizes;

  @override
  void initState() {
    super.initState();
    // Copy existing prizes or create default 1st, 2nd, 3rd place prizes if empty
    if (widget.tournament.prizes.isNotEmpty) {
      _prizes = widget.tournament.prizes.map((p) => p.copyWith()).toList();
    } else {
      _prizes = [
        TournamentPrizeEntity(
          id: 'temp_1',
          tournamentId: widget.tournament.id,
          placement: 1,
          rewards: [
            TournamentPrizeRewardEntity(
              id: 'temp_reward_1_1',
              prizeId: 'temp_1',
              type: TournamentPrizeType.trophy,
              titleAr: 'كأس البطولة',
              titleEn: 'Championship Trophy',
            ),
            TournamentPrizeRewardEntity(
              id: 'temp_reward_1_2',
              prizeId: 'temp_1',
              type: TournamentPrizeType.cash,
              titleAr: 'جائزة مالية',
              titleEn: 'Cash Prize',
              value: widget.tournament.prizePool > 0 ? widget.tournament.prizePool * 0.6 : 500,
              currency: 'EGP',
            ),
          ],
        ),
        TournamentPrizeEntity(
          id: 'temp_2',
          tournamentId: widget.tournament.id,
          placement: 2,
          rewards: [
            TournamentPrizeRewardEntity(
              id: 'temp_reward_2_1',
              prizeId: 'temp_2',
              type: TournamentPrizeType.cash,
              titleAr: 'جائزة المركز الثاني',
              titleEn: '2nd Place Prize',
              value: widget.tournament.prizePool > 0 ? widget.tournament.prizePool * 0.3 : 300,
              currency: 'EGP',
            ),
          ],
        ),
        TournamentPrizeEntity(
          id: 'temp_3',
          tournamentId: widget.tournament.id,
          placement: 3,
          rewards: [
            TournamentPrizeRewardEntity(
              id: 'temp_reward_3_1',
              prizeId: 'temp_3',
              type: TournamentPrizeType.points,
              titleAr: 'نقاط مكافأة',
              titleEn: 'Bonus Points',
              value: 500,
            ),
          ],
        ),
      ];
    }
  }

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

  void _addPlacement() {
    setState(() {
      final nextPlacement = _prizes.length + 1;
      final tempId = 'temp_${const Uuid().v4()}';
      _prizes.add(
        TournamentPrizeEntity(
          id: tempId,
          tournamentId: widget.tournament.id,
          placement: nextPlacement,
          rewards: [
            TournamentPrizeRewardEntity(
              id: 'temp_reward_${const Uuid().v4()}',
              prizeId: tempId,
              type: TournamentPrizeType.points,
              titleAr: 'نقاط مكافأة',
              titleEn: 'Bonus Points',
              value: 100,
            ),
          ],
        ),
      );
    });
  }

  void _removePlacement(int index) {
    if (_prizes.length <= 1) return;
    setState(() {
      _prizes.removeAt(index);
      // Re-index placements
      for (int i = 0; i < _prizes.length; i++) {
        _prizes[i] = _prizes[i].copyWith(placement: i + 1);
      }
    });
  }

  void _addReward(int placementIndex) {
    setState(() {
      final prize = _prizes[placementIndex];
      final newReward = TournamentPrizeRewardEntity(
        id: 'temp_reward_${const Uuid().v4()}',
        prizeId: prize.id,
        type: TournamentPrizeType.cash,
        titleAr: 'جائزة جديدة',
        titleEn: 'New Reward',
        currency: 'EGP',
      );
      final updatedRewards = [...prize.rewards, newReward];
      _prizes[placementIndex] = prize.copyWith(rewards: updatedRewards);
    });
  }

  void _removeReward(int placementIndex, int rewardIndex) {
    setState(() {
      final prize = _prizes[placementIndex];
      final updatedRewards = [...prize.rewards]..removeAt(rewardIndex);
      _prizes[placementIndex] = prize.copyWith(rewards: updatedRewards);
    });
  }

  void _updateReward(int placementIndex, int rewardIndex, TournamentPrizeRewardEntity updatedReward) {
    setState(() {
      final prize = _prizes[placementIndex];
      final updatedRewards = [...prize.rewards];
      updatedRewards[rewardIndex] = updatedReward;
      _prizes[placementIndex] = prize.copyWith(rewards: updatedRewards);
    });
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? true) {
      widget.onSave(_prizes);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '${AppStrings.managePrizes} - ${widget.tournament.title}',
      width: 800.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: AppStrings.savePrizes,
          icon: Icons.check,
          onPressed: _handleSave,
        ),
      ],
      child: Form(
        key: _formKey,
        child: SizedBox(
          height: 550.h,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.tournamentPrizes,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppButton(
                      text: AppStrings.addPlacement,
                      icon: Icons.add_circle_outline,
                      variant: AppButtonVariant.outlined,
                      fontSize: 12.sp,
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      onPressed: _addPlacement,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _prizes.length,
                  itemBuilder: (context, placementIndex) {
                    final prize = _prizes[placementIndex];
                    return _buildPlacementCard(prize, placementIndex);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementCard(TournamentPrizeEntity prize, int placementIndex) {
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
          // Header: Placement title & actions
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
                    onPressed: () => _addReward(placementIndex),
                  ),
                  if (_prizes.length > 1) ...[
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                      tooltip: AppStrings.cancel,
                      onPressed: () => _removePlacement(placementIndex),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // List of Rewards for this Placement
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
                return _buildRewardRow(
                  reward,
                  placementIndex,
                  rewardIndex,
                  canDelete: prize.rewards.length > 1,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRewardRow(
    TournamentPrizeRewardEntity reward,
    int placementIndex,
    int rewardIndex, {
    required bool canDelete,
  }) {
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
              // Type Dropdown Selector
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
                          _updateReward(
                            placementIndex,
                            rewardIndex,
                            reward.copyWith(type: newType),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Title Arabic
              Expanded(
                flex: 3,
                child: AppTextField(
                  initialValue: reward.titleAr ?? reward.title ?? '',
                  label: AppStrings.titleAr,
                  onChanged: (val) {
                    _updateReward(
                      placementIndex,
                      rewardIndex,
                      reward.copyWith(titleAr: val, title: val),
                    );
                  },
                ),
              ),
              SizedBox(width: 8.w),

              // Title English
              Expanded(
                flex: 3,
                child: AppTextField(
                  initialValue: reward.titleEn ?? '',
                  label: AppStrings.titleEn,
                  onChanged: (val) {
                    _updateReward(
                      placementIndex,
                      rewardIndex,
                      reward.copyWith(titleEn: val),
                    );
                  },
                ),
              ),
              if (canDelete) ...[
                SizedBox(width: 8.w),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.danger, size: 20),
                  tooltip: AppStrings.cancel,
                  onPressed: () => _removeReward(placementIndex, rewardIndex),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),

          // Value and Currency Row (depending on prize type)
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
                      _updateReward(
                        placementIndex,
                        rewardIndex,
                        reward.copyWith(value: parsed),
                      );
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
                      _updateReward(
                        placementIndex,
                        rewardIndex,
                        reward.copyWith(currency: val),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12.w),
              ],

              // Description Arabic
              Expanded(
                flex: 3,
                child: AppTextField(
                  initialValue: reward.descriptionAr ?? reward.description ?? '',
                  label: AppStrings.descriptionAr,
                  onChanged: (val) {
                    _updateReward(
                      placementIndex,
                      rewardIndex,
                      reward.copyWith(descriptionAr: val, description: val),
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),

              // Description English
              Expanded(
                flex: 3,
                child: AppTextField(
                  initialValue: reward.descriptionEn ?? '',
                  label: AppStrings.descriptionEn,
                  onChanged: (val) {
                    _updateReward(
                      placementIndex,
                      rewardIndex,
                      reward.copyWith(descriptionEn: val),
                    );
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
