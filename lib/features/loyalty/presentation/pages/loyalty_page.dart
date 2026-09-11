import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';
import '../cubit/loyalty_cubit.dart';
import '../cubit/loyalty_state.dart';
import '../widgets/loyalty_filters_bar.dart';
import '../widgets/loyalty_stats_tab.dart';
import '../widgets/referrals_tab.dart';
import '../widgets/tasks_tab.dart';
import '../widgets/levels_tab.dart';
import '../widgets/loyalty_data_table.dart';
import '../widgets/redemption_option_dialog.dart';

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<LoyaltyCubit>().changeTab(_tabController.index);
      }
    });

    context.read<LoyaltyCubit>().loadLoyaltyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          // Top Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.heading(AppStrings.loyaltySystemAndReferrals, fontSize: 28.sp),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => loyaltyCubit.loadLoyaltyData(),
                    icon: const Icon(Icons.refresh, color: AppColors.neonBlue),
                    tooltip: AppStrings.refresh,
                  ),
                  SizedBox(width: 12.w),
                  AppButton(
                    text: AppStrings.addReward,
                    onPressed: () => _showOptionDialog(context, loyaltyCubit),
                    icon: Icons.add,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Filters Bar
          const LoyaltyFiltersBar(),
          SizedBox(height: 20.h),

          // Custom Styled TabBar
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.neonBlue,
              labelColor: AppColors.neonBlue,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: AppStrings.loyaltyStatsTab, icon: const Icon(Icons.insights_rounded)),
                Tab(text: AppStrings.referralsTab, icon: const Icon(Icons.people_alt_outlined)),
                Tab(text: AppStrings.tasksTab, icon: const Icon(Icons.assignment_turned_in_outlined)),
                Tab(text: AppStrings.levelsTab, icon: const Icon(Icons.workspace_premium_outlined)),
                Tab(text: AppStrings.redemptionsTab, icon: const Icon(Icons.card_giftcard_outlined)),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // TabBarView Content
          Expanded(
            child: BlocBuilder<LoyaltyCubit, LoyaltyState>(
              builder: (context, state) {
                if (state.status == LoyaltyStatus.loading && state.stats == null) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
                }

                if (state.status == LoyaltyStatus.failure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText.body(state.errorMessage ?? AppStrings.error, color: AppColors.danger, fontSize: 16.sp),
                        SizedBox(height: 16.h),
                        AppButton(
                          text: AppStrings.retry,
                          onPressed: () => loyaltyCubit.loadLoyaltyData(),
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 0: Stats
                    state.stats != null
                        ? LoyaltyStatsTab(stats: state.stats!)
                        : const SizedBox.shrink(),

                    // Tab 1: Referrals
                    ReferralsTab(referrals: state.referrals),

                    // Tab 2: Tasks
                    TasksTab(tasks: state.tasks, cubit: loyaltyCubit),

                    // Tab 3: Levels
                    LevelsTab(levels: state.levels, cubit: loyaltyCubit),

                    // Tab 4: Redemption Options
                    LoyaltyDataTable(
                      options: state.options,
                      cubit: loyaltyCubit,
                      onEdit: (opt) => _showOptionDialog(context, loyaltyCubit, option: opt),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
