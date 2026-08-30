import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import '../cubit/permissions_cubit.dart';
import '../cubit/permissions_state.dart';
import '../../domain/entities/permission_item_entity.dart';

class LoungePermissionsSettingsTab extends StatefulWidget {
  const LoungePermissionsSettingsTab({super.key});

  @override
  State<LoungePermissionsSettingsTab> createState() => _LoungePermissionsSettingsTabState();
}

class _LoungePermissionsSettingsTabState extends State<LoungePermissionsSettingsTab> {
  @override
  void initState() {
    super.initState();
    context.read<PermissionsCubit>().fetchPermissions('cashier');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermissionsCubit, PermissionsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoleSelector(state.selectedRole),
            SizedBox(height: 32.h),
            if (state.status == PermissionsStatus.loading && state.permissions.isEmpty)
              const Center(child: CircularProgressIndicator(color: AppColors.neonBlue))
            else if (state.status == PermissionsStatus.failure && state.permissions.isEmpty)
              Center(child: AppText.body(state.errorMessage ?? 'Error loading permissions', color: AppColors.danger))
            else
              _buildPermissionsGrid(state.permissions, state.selectedRole),
          ],
        );
      },
    );
  }

  Widget _buildRoleSelector(String selectedRole) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'cashier', label: Text('role_cashier'.tr())),
        ButtonSegment(value: 'staff', label: Text('role_staff'.tr())),
      ],
      selected: {selectedRole},
      onSelectionChanged: (Set<String> newSelection) {
        context.read<PermissionsCubit>().fetchPermissions(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppColors.neonBlue;
          return AppColors.cardBackground;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.black;
          return AppColors.textPrimary;
        }),
      ),
    );
  }

  Widget _buildPermissionsGrid(List<PermissionItemEntity> permissions, String role) {
    final Map<String, List<PermissionItemEntity>> categories = {};
    for (var p in permissions) {
      categories.putIfAbsent(p.category, () => []).add(p);
    }

    // Sort categories to be consistent
    final sortedCategoryKeys = categories.keys.toList()..sort();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isMobile(context) ? 1 : 2,
        crossAxisSpacing: 24.w,
        mainAxisSpacing: 24.h,
        mainAxisExtent: Responsive.isMobile(context) ? 450.h : 400.h,
      ),
      itemCount: sortedCategoryKeys.length,
      itemBuilder: (context, index) {
        final category = sortedCategoryKeys[index];
        final categoryPermissions = categories[category]!;
        return _buildCategoryCard(category, categoryPermissions, role);
      },
    );
  }

  Widget _buildCategoryCard(String category, List<PermissionItemEntity> permissions, String role) {
    return Material(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
      child: Container(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getCategoryIcon(category),
                SizedBox(width: 12.w),
                AppText.heading(category.tr(), fontSize: 18.sp, color: AppColors.neonPurple),
              ],
            ),
            SizedBox(height: 16.h),
            const Divider(color: AppColors.divider),
            Expanded(
              child: ListView.separated(
                itemCount: permissions.length,
                separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (context, index) => _buildPermissionTile(permissions[index], role),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    if (category.contains('منيو') || category.contains('Menu')) {
      icon = Icons.restaurant_menu;
    } else if (category.contains('مالي') || category.contains('Financial')) {
      icon = Icons.account_balance_wallet_outlined;
    } else if (category.contains('وردية') || category.contains('Shift')) {
      icon = Icons.history_toggle_off;
    } else {
      icon = Icons.settings_outlined;
    }
    return Icon(icon, color: AppColors.neonPurple, size: 24.r);
  }

  Widget _buildPermissionTile(PermissionItemEntity p, String role) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SwitchListTile(
      value: p.isEnabled,
      onChanged: (val) {
        context.read<PermissionsCubit>().togglePermission(role, p.key, val);
      },
      title: AppText.body((isArabic ? p.nameAr : p.nameEn).tr(), fontWeight: FontWeight.bold),
      subtitle: AppText.body((isArabic ? p.descriptionAr : p.descriptionEn).tr(), color: AppColors.textSecondary, fontSize: 12.sp),
      activeColor: AppColors.neonBlue,
      contentPadding: EdgeInsets.zero,
    );
  }
}
