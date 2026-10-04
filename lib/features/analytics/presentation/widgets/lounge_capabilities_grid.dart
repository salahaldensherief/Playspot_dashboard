import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'planned_module_dialog.dart';

class _ModuleItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isActive;
  final String? route;

  const _ModuleItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isActive,
    this.route,
  });
}

class LoungeCapabilitiesGrid extends StatelessWidget {
  const LoungeCapabilitiesGrid({super.key});

  List<_ModuleItem> _getModules() {
    return [
      _ModuleItem(
        title: AppStrings.tournamentsEngineTitle,
        description: AppStrings.tournamentsEngineDesc,
        icon: Icons.emoji_events_outlined,
        color: AppColors.warning,
        isActive: true,
        route: RouterKeys.loungeAdminTournaments,
      ),
      _ModuleItem(
        title: AppStrings.smartRebookTitle,
        description: AppStrings.smartRebookDesc,
        icon: Icons.sync_rounded,
        color: AppColors.neonBlue,
        isActive: false,
      ),
      _ModuleItem(
        title: AppStrings.waitlistTitle,
        description: AppStrings.waitlistDesc,
        icon: Icons.notifications_active_outlined,
        color: AppColors.neonCyan,
        isActive: false,
      ),
      _ModuleItem(
        title: AppStrings.membershipsTitle,
        description: AppStrings.membershipsDesc,
        icon: Icons.card_membership_rounded,
        color: AppColors.neonPurple,
        isActive: false,
      ),
      _ModuleItem(
        title: AppStrings.pricingRulesTitle,
        description: AppStrings.pricingRulesDesc,
        icon: Icons.price_change_outlined,
        color: AppColors.neonGreen,
        isActive: false,
      ),
      _ModuleItem(
        title: AppStrings.gamerCrmTitle,
        description: AppStrings.gamerCrmDesc,
        icon: Icons.group_add_outlined,
        color: AppColors.neonBlue,
        isActive: false,
      ),
      _ModuleItem(
        title: AppStrings.missionsQuestsTitle,
        description: AppStrings.missionsQuestsDesc,
        icon: Icons.military_tech_outlined,
        color: AppColors.warning,
        isActive: false,
      ),
      _ModuleItem(
        title: AppStrings.groupSplitTitle,
        description: AppStrings.groupSplitDesc,
        icon: Icons.call_split_rounded,
        color: AppColors.neonCyan,
        isActive: false,
      ),
      _ModuleItem(
        title: AppStrings.auditTimelineTitle,
        description: AppStrings.auditTimelineDesc,
        icon: Icons.history_toggle_off_rounded,
        color: AppColors.danger,
        isActive: false,
      ),
      _ModuleItem(
        title: AppStrings.corporateEventsTitle,
        description: AppStrings.corporateEventsDesc,
        icon: Icons.celebration_outlined,
        color: AppColors.neonPurple,
        isActive: false,
      ),
    ];
  }

  void _onModuleTap(BuildContext context, _ModuleItem item) {
    if (item.isActive && item.route != null) {
      context.go(item.route!);
    } else {
      showDialog(
        context: context,
        builder: (_) => PlannedModuleDialog(
          title: item.title,
          description: item.description,
          icon: item.icon,
          accentColor: item.color,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final modules = _getModules();
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 16.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final double crossAxisCount = isDesktop
                  ? 5
                  : isTablet
                  ? 3
                  : (constraints.maxWidth > 400 ? 2 : 1);
              final double spacing = 12.w;
              final double itemWidth =
                  (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                  crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: 12.h,
                children: modules.map((m) {
                  return SizedBox(
                    width: itemWidth,
                    child: _buildModuleTile(context, m),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsetsDirectional.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.neonPurple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.apps_rounded,
            color: AppColors.neonPurple,
            size: 20.r,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.loungeOsModules,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                AppStrings.loungeOsModulesSubtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModuleTile(BuildContext context, _ModuleItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onModuleTap(context, item),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          constraints: BoxConstraints(minHeight: 110.h),
          padding: EdgeInsetsDirectional.all(12.r),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: item.isActive
                  ? item.color.withValues(alpha: 0.4)
                  : AppColors.divider.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsetsDirectional.all(6.r),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(item.icon, size: 18.r, color: item.color),
                  ),
                  _buildStatusChip(item),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                item.title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                item.description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.sp,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(_ModuleItem item) {
    if (item.isActive) {
      return Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: 6.w,
          vertical: 2.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          AppStrings.moduleStatusActive,
          style: TextStyle(
            color: AppColors.success,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        AppStrings.moduleStatusPlanned,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
