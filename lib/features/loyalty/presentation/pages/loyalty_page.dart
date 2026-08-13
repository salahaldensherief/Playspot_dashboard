import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';
import '../cubit/loyalty_cubit.dart';
import '../cubit/loyalty_state.dart';
import '../widgets/loyalty_stats_grid.dart';
import '../widgets/redemption_option_dialog.dart';

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
            builder: (context, state) {
              if (state.stats == null && state.status == LoyaltyStatus.loading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
              }
              if (state.stats != null) {
                return LoyaltyStatsGrid(stats: state.stats!);
              }
              return const SizedBox.shrink();
            },
          ),
          SizedBox(height: 32.h),
          AppText.subHeading(AppStrings.redemptionOptions, fontSize: 20.sp),
          SizedBox(height: 16.h),
          Expanded(
            child: BlocBuilder<LoyaltyCubit, LoyaltyState>(
              builder: (context, state) {
                if (state.status == LoyaltyStatus.loading && state.options.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
                }
                if (state.status == LoyaltyStatus.failure) {
                  return Center(child: AppText.body(state.errorMessage ?? 'Error', color: AppColors.danger));
                }
                if (state.options.isEmpty) {
                  return _buildEmptyState();
                }
                return _LoyaltyDataTable(options: state.options, cubit: loyaltyCubit, onEdit: (opt) => _showOptionDialog(context, loyaltyCubit, option: opt));
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
          AppText.body('No redemption options found.', fontSize: 18.sp),
        ],
      ),
    );
  }
}

class _LoyaltyDataTable extends StatelessWidget {
  final List<RedemptionOptionEntity> options;
  final LoyaltyCubit cubit;
  final Function(RedemptionOptionEntity) onEdit;

  const _LoyaltyDataTable({required this.options, required this.cubit, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return DataTableWidget(
      columns: const [
        'Title',
        'Cost (Points)',
        'Reward',
        'Status',
        'Actions',
      ],
      rows: options.map((opt) => DataRow(
        cells: [
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText.body(opt.titleEn, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                AppText.body(opt.titleAr, color: AppColors.textSecondary, fontSize: 11.sp),
              ],
            ),
          ),
          DataCell(AppText.body(opt.pointsCost.toString())),
          DataCell(
            AppText.body(
              opt.rewardType == 'discount_fixed' 
                ? "${opt.rewardValue.toStringAsFixed(0)} EGP Off" 
                : "Free Hour",
              color: AppColors.neonBlue,
            )
          ),
          DataCell(
            opt.isActive ? StatusBadge.success('ACTIVE') : StatusBadge.danger('INACTIVE')
          ),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                  onPressed: () => onEdit(opt),
                ),
                IconButton(
                  icon: Icon(
                    opt.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                    color: opt.isActive ? AppColors.warning : AppColors.success, 
                    size: 20
                  ),
                  onPressed: () => cubit.toggleOptionStatus(opt.id, !opt.isActive),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                  onPressed: () => _confirmDelete(context, opt),
                ),
              ],
            ),
          ),
        ],
      )).toList(),
    );
  }

  void _confirmDelete(BuildContext context, RedemptionOptionEntity option) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteWarning} "${option.titleEn}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagContext), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              cubit.deleteOption(option.id);
              Navigator.pop(diagContext);
            }, 
            child: Text(AppStrings.delete, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
