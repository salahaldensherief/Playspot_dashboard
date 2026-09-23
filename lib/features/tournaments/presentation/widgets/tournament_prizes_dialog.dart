import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_prize_entity.dart';
import '../../domain/entities/tournament_prize_reward_entity.dart';
import 'tournament_placement_card.dart';

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
    if (widget.tournament.prizes.isNotEmpty) {
      _prizes = widget.tournament.prizes.map((p) => p.copyWith()).toList();
    } else {
      _prizes = _createDefaultPrizes();
    }
  }

  List<TournamentPrizeEntity> _createDefaultPrizes() {
    final pool = widget.tournament.prizePool;
    return [
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
            value: pool > 0 ? pool * 0.6 : 500,
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
            value: pool > 0 ? pool * 0.3 : 300,
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
                    return TournamentPlacementCard(
                      key: ValueKey(prize.id),
                      prize: prize,
                      placementIndex: placementIndex,
                      canDeletePlacement: _prizes.length > 1,
                      onAddReward: () => _addReward(placementIndex),
                      onRemovePlacement: () => _removePlacement(placementIndex),
                      onUpdateReward: (rewardIdx, updated) =>
                          _updateReward(placementIndex, rewardIdx, updated),
                      onRemoveReward: (rewardIdx) =>
                          _removeReward(placementIndex, rewardIdx),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
