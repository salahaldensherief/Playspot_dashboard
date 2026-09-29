import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_adaptive_page_header.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/core/utils/permission_extension.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/features/canteen/presentation/canteen_cubit.dart';
import 'package:play_spot_dashboard/features/canteen/presentation/widgets/canteen_combos_tab.dart';
import 'package:play_spot_dashboard/features/canteen/presentation/widgets/canteen_upsell_tab.dart';
import 'package:play_spot_dashboard/features/canteen/presentation/widgets/combo_editor_modal.dart';
import 'package:play_spot_dashboard/features/canteen/presentation/widgets/upsell_rule_editor_modal.dart';
import '../cubit/extras_cubit.dart';
import '../widgets/extra_dialog.dart';
import '../widgets/extras_grid.dart';

class ExtrasManagementPage extends StatefulWidget {
  const ExtrasManagementPage({super.key});

  @override
  State<ExtrasManagementPage> createState() => _ExtrasManagementPageState();
}

class _ExtrasManagementPageState extends State<ExtrasManagementPage> {
  String? _loadedLoungeId;
  int _selectedTabIndex = 0;

  void _checkAndLoadData(BuildContext context, String loungeId) {
    if (loungeId.isNotEmpty && _loadedLoungeId != loungeId) {
      _loadedLoungeId = loungeId;
      context.read<ExtrasCubit>().loadExtras(loungeId);
      context.read<CanteenCubit>().loadAll(loungeId);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginState = context.read<LoginCubit>().state;
      final loungeId = loginState.user?.loungeId ?? loginState.userLounge?.id ?? '';
      _checkAndLoadData(context, loungeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (prev, curr) =>
          prev.user?.loungeId != curr.user?.loungeId ||
          prev.userLounge?.id != curr.userLounge?.id,
      listener: (context, loginState) {
        final loungeId = loginState.user?.loungeId ?? loginState.userLounge?.id ?? '';
        _checkAndLoadData(context, loungeId);
      },
      child: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, loginState) {
          final user = loginState.user;
          final loungeId = user?.loungeId ?? loginState.userLounge?.id ?? '';

          if (loungeId.isNotEmpty && _loadedLoungeId != loungeId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndLoadData(context, loungeId);
            });
          }

          return DashboardLayout(
            title: AppStrings.extras,
            activeRoute: 'Extras',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, loungeId),
                SizedBox(height: 16.h),
                _buildTabBar(),
                SizedBox(height: 20.h),
                _buildTabContent(loungeId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabItem(0, AppStrings.singleItemsTab, Icons.restaurant_menu_rounded),
          _buildTabItem(1, AppStrings.combosTab, Icons.fastfood_rounded),
          _buildTabItem(2, AppStrings.upsellTab, Icons.bolt_rounded),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        constraints: BoxConstraints(minHeight: 48.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.r,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: 8.w),
            AppText.body(
              title,
              fontSize: 13.sp,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String loungeId) {
    switch (_selectedTabIndex) {
      case 1:
        return CanteenCombosTab(loungeId: loungeId);
      case 2:
        return CanteenUpsellTab(loungeId: loungeId);
      case 0:
      default:
        return const ExtrasGrid();
    }
  }

  Widget _buildHeader(BuildContext context, String loungeId) {
    final bool canEdit = context.hasPermission('menu_manage_items');
    Widget? primaryAction;

    if (canEdit) {
      if (_selectedTabIndex == 0) {
        final cubit = context.read<ExtrasCubit>();
        primaryAction = AppButton(
          text: AppStrings.addExtraItem,
          icon: Icons.add,
          onPressed: () => _openAddDialog(context, loungeId, cubit),
        );
      } else if (_selectedTabIndex == 1) {
        primaryAction = AppButton(
          text: AppStrings.addCombo,
          icon: Icons.add,
          onPressed: () => _openAddComboDialog(context, loungeId),
        );
      } else if (_selectedTabIndex == 2) {
        primaryAction = AppButton(
          text: AppStrings.addUpsellRule,
          icon: Icons.add,
          onPressed: () => _openAddUpsellRuleDialog(context, loungeId),
        );
      }
    }

    return AppAdaptivePageHeader(
      title: AppStrings.menuManagement,
      subtitle: AppStrings.menuManagementSubtitle,
      primaryAction: primaryAction,
    );
  }

  void _openAddDialog(BuildContext context, String loungeId, ExtrasCubit cubit) {
    final loginCubit = context.read<LoginCubit>();
    final permissionsCubit = context.read<PermissionsCubit>();

    showDialog(
      context: context,
      builder: (diagContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: loginCubit),
          BlocProvider.value(value: permissionsCubit),
        ],
        child: ExtraDialog(
          loungeId: loungeId,
          onSave: (newExtra) => cubit.addExtra(newExtra),
        ),
      ),
    );
  }

  void _openAddComboDialog(BuildContext context, String loungeId) {
    final canteenCubit = context.read<CanteenCubit>();
    final extrasCubit = context.read<ExtrasCubit>();

    showDialog(
      context: context,
      builder: (ctx) => ComboEditorModal(
        loungeId: loungeId,
        availableExtras: extrasCubit.state.extras,
        onSave: (combo) => canteenCubit.saveCombo(combo),
      ),
    );
  }

  void _openAddUpsellRuleDialog(BuildContext context, String loungeId) {
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
}
