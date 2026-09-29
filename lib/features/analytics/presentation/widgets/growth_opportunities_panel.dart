import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_section_header.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import '../lounge_stats_cubit.dart';
import '../lounge_stats_state.dart';

class GrowthOpportunitiesPanel extends StatelessWidget {
  final bool isSuperAdmin;

  const GrowthOpportunitiesPanel({super.key, this.isSuperAdmin = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoungeStatsCubit, LoungeStatsState>(
      buildWhen: (prev, curr) =>
          prev.stats?.occupancyRate != curr.stats?.occupancyRate,
      builder: (context, state) {
        final double occupancyRate = state.stats?.occupancyRate ?? 0.0;
        final bool isHighOccupancy = occupancyRate >= 0.7;

        return Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 16.h),
              _OpportunityTile(
                icon: isHighOccupancy
                    ? Icons.trending_up_rounded
                    : Icons.local_offer_outlined,
                title: isHighOccupancy
                    ? AppStrings.highOccupancyTip
                    : AppStrings.boostOccupancyTip,
                description: isHighOccupancy
                    ? AppStrings.highOccupancyDesc
                    : AppStrings.boostOccupancyDesc,
                color: isHighOccupancy
                    ? AppColors.neonGreen
                    : AppColors.neonPurple,
                actionText: AppStrings.createPromo,
                onAction: () => context.push(RouterKeys.loungeAdminMarketing),
              ),
              SizedBox(height: 10.h),
              _OpportunityTile(
                icon: Icons.fastfood_outlined,
                title: AppStrings.canteenUpsellTip,
                description: AppStrings.canteenUpsellDesc,
                color: AppColors.neonCyan,
                actionText: AppStrings.viewCanteen,
                onAction: () => context.push(RouterKeys.loungeAdminExtras),
              ),
              SizedBox(height: 10.h),
              _OpportunityTile(
                icon: Icons.emoji_events_outlined,
                title: AppStrings.tournamentsTip,
                description: AppStrings.tournamentsDesc,
                color: Colors.amberAccent,
                actionText: AppStrings.viewTournaments,
                onAction: () => context.push(RouterKeys.loungeAdminTournaments),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return AppSectionHeader(
      title: AppStrings.growthOpportunities,
      icon: Icons.rocket_launch_outlined,
      iconColor: AppColors.neonPurple,
    );
  }
}

class _OpportunityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String actionText;
  final VoidCallback onAction;

  const _OpportunityTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          AppButton(
            text: actionText,
            variant: AppButtonVariant.outlined,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
