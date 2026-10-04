import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_empty_state_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import '../../../lounges/presentation/cubit/extras_cubit.dart';
import '../canteen_cubit.dart';
import '../canteen_state.dart';
import 'upsell_rule_card.dart';
import 'upsell_rule_editor_modal.dart';

class CanteenUpsellTab extends StatelessWidget {
  final String loungeId;

  const CanteenUpsellTab({super.key, required this.loungeId});

  void _openAddModal(BuildContext context) {
    final canteenCubit = context.read<CanteenCubit>();
    final extrasCubit = context.read<ExtrasCubit>();

    showDialog(
      context: context,
      builder: (ctx) => UpsellRuleEditorModal(
        loungeId: loungeId,
        availableExtras: extrasCubit.state.extras,
        availableCombos: canteenCubit.state.combos,
        onSave: (rule) => canteenCubit.saveUpsellRule(rule),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return BlocBuilder<CanteenCubit, CanteenState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.upsellRules != curr.upsellRules ||
          prev.conversions != curr.conversions ||
          prev.isSaving != curr.isSaving,
      builder: (context, state) {
        if (state.status == CanteenStatus.loading &&
            state.upsellRules.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: ShimmerLoading.rectangular(
              width: double.infinity,
              height: 200.h,
            ),
          );
        }

        // Aggregate overall KPIs
        int totalImpressions = 0;
        int totalConversions = 0;
        double totalRevenue = 0.0;
        for (final conv in state.conversions) {
          totalImpressions += conv.impressions;
          totalConversions += conv.conversions;
          totalRevenue += conv.revenueGenerated;
        }
        final avgRate = totalImpressions > 0
            ? (totalConversions / totalImpressions) * 100.0
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall KPIs Banner
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    AppStrings.impressionsCount,
                    '$totalImpressions',
                    AppColors.textSecondary,
                  ),
                  Container(
                    width: 1.w,
                    height: 36.h,
                    color: AppColors.borderDefault,
                  ),
                  _buildSummaryItem(
                    AppStrings.conversionsCount,
                    '$totalConversions',
                    AppColors.success,
                  ),
                  Container(
                    width: 1.w,
                    height: 36.h,
                    color: AppColors.borderDefault,
                  ),
                  _buildSummaryItem(
                    AppStrings.conversionRate,
                    '${avgRate.toStringAsFixed(1)}%',
                    AppColors.primary,
                  ),
                  Container(
                    width: 1.w,
                    height: 36.h,
                    color: AppColors.borderDefault,
                  ),
                  _buildSummaryItem(
                    AppStrings.revenueGenerated,
                    '${totalRevenue.toStringAsFixed(0)} ${AppStrings.egp}',
                    AppColors.warning,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Top action bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.subHeading(
                  '${AppStrings.upsellRulesManager} (${state.upsellRules.length})',
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                AppButton(
                  text: AppStrings.addUpsellRule,
                  icon: Icons.add,
                  onPressed: () => _openAddModal(context),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            if (state.upsellRules.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: AppEmptyStateWidget(
                  title: 'upsell_rules_empty_title'.tr(),
                  subtitle: 'upsell_rules_empty_description'.tr(),
                  icon: Icons.lightbulb_outline,
                  actionText: AppStrings.addUpsellRule,
                  onActionTextPressed: () => _openAddModal(context),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final crossAxisCount = isWide ? 2 : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: 230.h,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                    ),
                    itemCount: state.upsellRules.length,
                    itemBuilder: (context, index) {
                      final rule = state.upsellRules[index];
                      final conv = state.getConversionForRule(rule.id);
                      final canteenCubit = context.read<CanteenCubit>();
                      final extrasCubit = context.read<ExtrasCubit>();

                      return UpsellRuleCard(
                        rule: rule,
                        conversion: conv,
                        onToggleActive: (_) =>
                            canteenCubit.toggleUpsellRuleActive(rule),
                        onDelete: () => canteenCubit.deleteUpsellRule(rule.id),
                        onEdit: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => UpsellRuleEditorModal(
                              loungeId: loungeId,
                              initialRule: rule,
                              availableExtras: extrasCubit.state.extras,
                              availableCombos: canteenCubit.state.combos,
                              onSave: (updated) =>
                                  canteenCubit.saveUpsellRule(updated),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryItem(String title, String val, Color valColor) {
    return Column(
      children: [
        AppText.body(title, fontSize: 11.sp, color: AppColors.textMuted),
        SizedBox(height: 4.h),
        AppText.subHeading(
          val,
          fontSize: 16.sp,
          color: valColor,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }
}
