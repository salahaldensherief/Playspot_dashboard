import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive/responsive.dart';
import '../../core/router/router_keys.dart';
import '../../core/utils/permission_extension.dart';
import '../../features/permissions/presentation/cubit/permissions_cubit.dart';
import '../../features/permissions/presentation/cubit/permissions_state.dart';
import '../app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/app_dialog.dart';
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

        return BlocBuilder<PermissionsCubit, PermissionsState>(
          builder: (context, permState) {
            return Container(
              width: Responsive.isDesktop(context) ? 260.w : double.infinity,
              decoration: BoxDecoration(
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
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.logoutConfirmation,
      message: AppStrings.logoutWarning,
      confirmText: AppStrings.logout,
      confirmColor: AppColors.danger,
    );

    if (confirmed == true && context.mounted) {
      context.read<LoginCubit>().logout();
    }
  }

  String _getRoleLabel(UserEntity user) {
    if (user.role == UserRole.superAdmin) return AppStrings.superAdmin;
    if (user.role == UserRole.owner) return AppStrings.loungeOwnerLabel;
    if (user.role == UserRole.manager) return AppStrings.loungeManager;
    if (user.role == UserRole.cashier) return AppStrings.cashierLabel;
    return 'Staff';
  }

  Widget _buildLogo(UserEntity? user) {
    final String roleLabel = user != null ? _getRoleLabel(user) : 'Staff';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withValues(alpha: 0.1),
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
        icon: Icons.verified_user_outlined,
        label: AppStrings.kycReviews,
        isActive: activeRoute == AppStrings.kycReviews,
        onTap: () => context.go(RouterKeys.superAdminKyc),
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

    final canViewBookings = context.hasPermission('bookings_view') || context.hasPermission('pos_view_menu');
    final canViewRooms = context.hasPermission('rooms_view');
    final canViewExtras = context.hasPermission('menu_view');
    final canViewReviews = context.hasPermission('reviews_view');
    final canManageMarketing = context.hasPermission('marketing_manage');
    final canManageStaff = context.hasPermission('staff_management');
    final canViewShiftHistory = context.hasPermission('shifts_view');
    final canViewReports = context.hasPermission('reports_view');
    final canEditLoungeProfile = context.hasPermission('lounge_profile_edit');

    return [
      _SidebarItem(
        icon: Icons.analytics_outlined,
        label: AppStrings.dashboard,
        isActive: activeRoute == AppStrings.dashboard,
        onTap: () => context.go(RouterKeys.loungeAdminDashboard),
      ),

      // Common: Live Operations (Sensors/Bookings)
      if (canViewBookings)
        _SidebarItem(
          icon: Icons.sensors,
          label: AppStrings.bookings,
          isActive: activeRoute == AppStrings.bookings,
          onTap: () => context.go(RouterKeys.loungeAdminLiveOps),
        ),
      
      // Setup: Rooms & Extras
      if (canViewRooms)
        _SidebarItem(
          icon: Icons.meeting_room_outlined,
          label: AppStrings.rooms,
          isActive: activeRoute == AppStrings.rooms,
          onTap: () => context.go(RouterKeys.loungeAdminRooms),
        ),

      if (canViewExtras)
        _SidebarItem(
          icon: Icons.restaurant_menu,
          label: AppStrings.extras,
          isActive: activeRoute == AppStrings.extras,
          onTap: () => context.go(RouterKeys.loungeAdminExtras),
        ),

      if (canViewReviews)
        _SidebarItem(
          icon: Icons.star_outline_rounded,
          label: AppStrings.loungeReviews,
          isActive: activeRoute == AppStrings.loungeReviews,
          onTap: () => context.go(RouterKeys.loungeAdminReviews),
        ),

      // Management Level
      if (canManageMarketing)
        _SidebarItem(
          icon: Icons.campaign_outlined,
          label: AppStrings.marketing,
          isActive: activeRoute == AppStrings.marketing,
          onTap: () => context.go(RouterKeys.loungeAdminMarketing),
        ),

      if (canManageStaff)
        _SidebarItem(
          icon: Icons.people_outline,
          label: AppStrings.staffManagement,
          isActive: activeRoute == AppStrings.staffManagement,
          onTap: () => context.go(RouterKeys.loungeAdminStaff),
        ),

      // History & Reports
      if (canViewShiftHistory)
        _SidebarItem(
          icon: Icons.history_outlined,
          label: AppStrings.shiftHistory,
          isActive: activeRoute == AppStrings.shiftHistory,
          onTap: () => context.go('/lounge-admin/shifts'),
        ),

      if (canViewReports)
        _SidebarItem(
          icon: Icons.assessment_outlined,
          label: AppStrings.monthlyReports,
          isActive: activeRoute == AppStrings.monthlyReports,
          onTap: () => context.go('/lounge-admin/reports'),
        ),

      // Profile & Settings
      if (canEditLoungeProfile)
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
            ? Border.all(color: AppColors.sidebarActiveBorder.withValues(alpha: 0.5))
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
