import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/router/router_keys.dart';
import '../app_strings.dart';
import '../theme/app_colors.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/auth/presentation/login/login_state.dart';

class DashboardSidebar extends StatelessWidget {
  final String activeRoute;
  const DashboardSidebar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) => prev.user != curr.user,
      builder: (context, state) {
        final user = state.user;
        final isSuperAdmin = user?.isSuperAdmin ?? false;

        return Container(
          width: 260.w,
          decoration: const BoxDecoration(
            color: AppColors.sidebarBackground,
            border: Border(right: BorderSide(color: AppColors.borderDefault)),
          ),
          child: Column(
            children: [
              SizedBox(height: 32.h),
              _buildLogo(user),
              SizedBox(height: 40.h),
              if (isSuperAdmin) 
                ..._buildSuperAdminItems(context) 
              else 
                ..._buildLoungeStaffItems(context, user),
              const Spacer(),
              _SidebarItem(
                icon: Icons.language,
                label: context.locale.languageCode == 'en' ? 'العربية' : 'English',
                isActive: false,
                onTap: () {
                  if (context.locale.languageCode == 'en') {
                    context.setLocale(const Locale('ar'));
                  } else {
                    context.setLocale(const Locale('en'));
                  }
                },
              ),
              _SidebarItem(
                icon: Icons.logout,
                label: AppStrings.logout,
                isActive: false,
                onTap: () => context.read<LoginCubit>().logout(),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo(UserEntity? user) {
    String roleLabel = 'Staff';
    if (user != null) {
      if (user.isSuperAdmin) roleLabel = AppStrings.superAdmin;
      else if (user.isOwner) roleLabel = AppStrings.loungeOwnerLabel;
      else if (user.isManager) roleLabel = AppStrings.loungeManager;
      else if (user.isCashier) roleLabel = AppStrings.cashierLabel;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.neonPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.sports_esports, color: AppColors.neonBlue, size: 24.r),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PlaySpot',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontFamily: 'Orbitron',
                ),
              ),
              Text(
                roleLabel,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSuperAdminItems(BuildContext context) {
    return [
      _SidebarItem(
        icon: Icons.analytics_outlined,
        label: AppStrings.analytics,
        isActive: activeRoute == AppStrings.dashboard,
        onTap: () => context.go(RouterKeys.superAdminDashboard),
      ),
      _SidebarItem(
        icon: Icons.business_outlined,
        label: AppStrings.lounges,
        isActive: activeRoute == AppStrings.lounges,
        onTap: () => context.go(RouterKeys.superAdminLounges),
      ),
      _SidebarItem(
        icon: Icons.people_outline,
        label: AppStrings.userLabel,
        isActive: activeRoute == AppStrings.users,
        onTap: () => context.go(RouterKeys.superAdminUsers),
      ),
      _SidebarItem(
        icon: Icons.account_balance_wallet_outlined,
        label: AppStrings.payouts,
        isActive: activeRoute == AppStrings.payouts,
        onTap: () => context.go(RouterKeys.superAdminPayouts),
      ),
      _SidebarItem(
        icon: Icons.history_outlined,
        label: AppStrings.shiftHistory,
        isActive: activeRoute == AppStrings.shiftHistory,
        onTap: () => context.go(RouterKeys.superAdminShifts),
      ),
    ];
  }

  List<Widget> _buildLoungeStaffItems(BuildContext context, UserEntity? user) {
    if (user == null) return [];

    return [
      // Common: Live Operations (Sensors/Bookings)
      _SidebarItem(
        icon: Icons.sensors,
        label: AppStrings.bookings,
        isActive: activeRoute == AppStrings.bookings,
        onTap: () => context.go(RouterKeys.loungeAdminLiveOps),
      ),
      
      // Setup: Rooms & Extras
      _SidebarItem(
        icon: Icons.meeting_room_outlined,
        label: AppStrings.rooms,
        isActive: activeRoute == AppStrings.rooms,
        onTap: () => context.go(RouterKeys.loungeAdminRooms),
      ),

      _SidebarItem(
        icon: Icons.restaurant_menu,
        label: AppStrings.extras,
        isActive: activeRoute == AppStrings.extras,
        onTap: () => context.go(RouterKeys.loungeAdminExtras),
      ),

      // Management Level
      if (user.canManageMarketing)
        _SidebarItem(
          icon: Icons.campaign_outlined,
          label: AppStrings.marketing,
          isActive: activeRoute == AppStrings.marketing,
          onTap: () => context.go(RouterKeys.loungeAdminMarketing),
        ),

      if (user.canManageStaff)
        _SidebarItem(
          icon: Icons.people_outline,
          label: AppStrings.staffManagement,
          isActive: activeRoute == AppStrings.staffManagement,
          onTap: () => context.go(RouterKeys.loungeAdminStaff),
        ),

      // History (All Staff can see their/lounge history)
      _SidebarItem(
        icon: Icons.history_outlined,
        label: AppStrings.shiftHistory,
        isActive: activeRoute == AppStrings.shiftHistory,
        onTap: () => context.go('/lounge-admin/shifts'),
      ),

      // Financial Reports (Owner/SuperAdmin)
      if (user.canViewFinancials)
        _SidebarItem(
          icon: Icons.assessment_outlined,
          label: AppStrings.monthlyReports,
          isActive: activeRoute == AppStrings.monthlyReports,
          onTap: () => context.go('/lounge-admin/reports'),
        ),

      // Profile & Settings
      if (user.canEditLoungeProfile)
        _SidebarItem(
          icon: Icons.settings_outlined,
          label: AppStrings.loungeProfile,
          isActive: activeRoute == AppStrings.loungeProfile,
          onTap: () => context.go(RouterKeys.loungeAdminProfile),
        ),

      _SidebarItem(
        icon: Icons.person_outline,
        label: AppStrings.myProfile,
        isActive: activeRoute == AppStrings.myProfile,
        onTap: () => context.go(RouterKeys.profile),
      ),
    ];
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppColors.sidebarActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: isActive 
            ? Border.all(color: AppColors.sidebarActiveBorder.withOpacity(0.5))
            : null,
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: ListTile(
            leading: Icon(
              icon,
              color: isActive ? AppColors.neonBlue : AppColors.textSecondary,
              size: 20.r,
            ),
            title: Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            onTap: onTap,
            dense: true,
          ),
        ),
      ),
    );
  }
}
