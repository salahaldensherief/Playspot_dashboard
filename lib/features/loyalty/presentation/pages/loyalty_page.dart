import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';
import '../cubit/loyalty_cubit.dart';
import '../cubit/loyalty_state.dart';
import '../widgets/loyalty_stats_grid.dart';
import '../widgets/redemption_option_dialog.dart';
import '../widgets/loyalty_data_table.dart';

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> {
  @override
  void initState() {
    super.initState();
    context.read<LoyaltyCubit>().loadLoyaltyData();
  }

  void _showOptionDialog(BuildContext context, LoyaltyCubit cubit, {RedemptionOptionEntity? option}) {
    showDialog(
      context: context,
      builder: (diagContext) => RedemptionOptionDialog(
        option: option,
        onSave: (newOption) {
          if (option == null) {
            cubit.createOption(newOption);
          } else {
            cubit.updateOption(newOption.id, {
              'title_ar': newOption.titleAr,
              'title_en': newOption.titleEn,
              'description_ar': newOption.descriptionAr,
              'description_en': newOption.descriptionEn,
              'points_cost': newOption.pointsCost,
              'reward_type': newOption.rewardType,
              'reward_value': newOption.rewardValue,
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyCubit = context.read<LoyaltyCubit>();

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.heading(AppStrings.loyaltyRewards, fontSize: 32.sp),
              AppButton(
                text: AppStrings.addReward,
                onPressed: () => _showOptionDialog(context, loyaltyCubit),
                icon: Icons.add,
              ),
            ],
          ),
          SizedBox(height: 32.h),
          BlocBuilder<LoyaltyCubit, LoyaltyState>(
            buildWhen: (prev, curr) => prev.stats != curr.stats || prev.status != curr.status,
            builder: (context, state) {
              if (state.stats == null && state.status == LoyaltyStatus.loading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
              }
              final stats = state.stats;
              if (stats != null) {
                return LoyaltyStatsGrid(stats: stats);
              }
              return const SizedBox.shrink();
            },
          ),
          SizedBox(height: 32.h),
          AppText.subHeading(AppStrings.redemptionOptions, fontSize: 20.sp),
          SizedBox(height: 16.h),
          Expanded(
            child: BlocBuilder<LoyaltyCubit, LoyaltyState>(
              buildWhen: (prev, curr) => prev.options != curr.options || prev.status != curr.status,
              builder: (context, state) {
                if (state.status == LoyaltyStatus.loading && state.options.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
                }
                if (state.status == LoyaltyStatus.failure) {
                  return Center(child: AppText.body(state.errorMessage ?? AppStrings.error, color: AppColors.danger));
                }
                if (state.options.isEmpty) {
                  return _buildEmptyState();
                }
                return LoyaltyDataTable(
                  options: state.options, 
                  cubit: loyaltyCubit, 
                  onEdit: (opt) => _showOptionDialog(context, loyaltyCubit, option: opt),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard_outlined, color: AppColors.textSecondary, size: 64.r),
          SizedBox(height: 16.h),
          AppText.body(AppStrings.noResultsMatching, fontSize: 18.sp),
        ],
      ),
    );
  }
}
