import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../art_core/app_strings.dart';
import '../../../art_core/theme/app_colors.dart';
import '../../../art_core/widgets/app_button.dart';
import '../../../art_core/widgets/app_section_header.dart';
import '../../../core/di/di.dart';
import '../../../core/utils/permission_extension.dart';
import '../../auth/presentation/login/login_cubit.dart';
import '../domain/entities/pricing_rule_entity.dart';
import 'pricing_cubit.dart';
import 'pricing_state.dart';
import 'widgets/pricing_grouped_rules_list.dart';
import 'widgets/pricing_rule_editor_drawer.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PricingCubit>(
      create: (_) => sl<PricingCubit>(),
      child: const _PricingScreenContent(),
    );
  }
}

class _PricingScreenContent extends StatefulWidget {
  const _PricingScreenContent();

  @override
  State<_PricingScreenContent> createState() => _PricingScreenContentState();
}

class _PricingScreenContentState extends State<_PricingScreenContent> {
  bool _isDrawerOpen = false;
  PricingRuleEntity? _selectedRuleForEdit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<LoginCubit>().state.user;
      final loungeId = user?.loungeId ?? '';
      context.read<PricingCubit>().loadPricingRules(loungeId: loungeId);
    });
  }

  void _openDrawer([PricingRuleEntity? rule]) {
    setState(() {
      _selectedRuleForEdit = rule;
      _isDrawerOpen = true;
    });
  }

  void _closeDrawer() {
    setState(() {
      _isDrawerOpen = false;
      _selectedRuleForEdit = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';

    // Permission Guard
    final bool canManagePricing = user != null &&
        (user.isSuperAdmin ||
            user.isOwner ||
            context.hasPermission('pricing.manage') ||
            context.hasPermission('pricing_manage'));

    if (!canManagePricing) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Center(
          child: Container(
            margin: EdgeInsets.all(24.r),
            padding: EdgeInsets.all(32.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.style_outlined,
                    size: 56.r, color: AppColors.textSecondary),
                SizedBox(height: 16.h),
                Text(
                  AppStrings.accessDeniedAudit,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AppSectionHeader(
                  title: AppStrings.pricingEngineTitle,
                  subtitle: AppStrings.pricingRulesDesc,
                  icon: Icons.style_rounded,
                  iconColor: AppColors.neonBlue,
                  action: AppButton(
                    text: AppStrings.addPricingRule,
                    icon: Icons.add_rounded,
                    backgroundColor: AppColors.neonBlue,
                    onPressed: () => _openDrawer(),
                  ),
                ),
                SizedBox(height: 16.h),

                // Grouping Selector
                BlocBuilder<PricingCubit, PricingState>(
                  buildWhen: (prev, curr) => prev.groupBy != curr.groupBy,
                  builder: (context, state) {
                    return Row(
                      children: [
                        _buildGroupChip(
                          context,
                          label: AppStrings.groupedByLounge,
                          groupBy: PricingGroupBy.lounge,
                          current: state.groupBy,
                        ),
                        SizedBox(width: 8.w),
                        _buildGroupChip(
                          context,
                          label: AppStrings.groupedBySpaceType,
                          groupBy: PricingGroupBy.spaceType,
                          current: state.groupBy,
                        ),
                        SizedBox(width: 8.w),
                        _buildGroupChip(
                          context,
                          label: AppStrings.groupedByRoom,
                          groupBy: PricingGroupBy.room,
                          current: state.groupBy,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 16.h),

                // Rules List
                Expanded(
                  child: BlocBuilder<PricingCubit, PricingState>(
                    builder: (context, state) {
                      if (state.status == PricingStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return PricingGroupedRulesList(
                        rules: state.rules,
                        groupBy: state.groupBy,
                        onEdit: (rule) => _openDrawer(rule),
                        onDelete: (rule) {
                          context
                              .read<PricingCubit>()
                              .deleteRule(rule.id, loungeId: loungeId);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Slide-in Drawer overlay
          if (_isDrawerOpen) ...[
            GestureDetector(
              onTap: _closeDrawer,
              child: Container(
                color: Colors.black.withAlpha(120),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: PricingRuleEditorDrawer(
                loungeId: loungeId,
                existingRule: _selectedRuleForEdit,
                onClose: _closeDrawer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupChip(
    BuildContext context, {
    required String label,
    required PricingGroupBy groupBy,
    required PricingGroupBy current,
  }) {
    final isSelected = groupBy == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.neonBlue,
      backgroundColor: AppColors.cardBackground,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 12.sp,
      ),
      onSelected: (_) {
        context.read<PricingCubit>().changeGroupBy(groupBy);
      },
    );
  }
}
