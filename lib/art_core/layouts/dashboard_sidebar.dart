import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/router/router_keys.dart';
import '../app_strings.dart';
import '../theme/app_colors.dart';
import '../../features/auth/domain/entities/admin_entity.dart';
import '../../features/auth/presentation/login/login_cubit.dart';

class DashboardSidebar extends StatelessWidget {
  final String activeRoute;
  const DashboardSidebar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final admin = context.read<LoginCubit>().state.admin;
    final isSuperAdmin = admin?.role == AdminRole.superAdmin;

    return Container(
      width: 260.w,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Column(
        children: [
          SizedBox(height: 32.h),
          _buildLogo(admin),
          SizedBox(height: 40.h),
          if (isSuperAdmin) ..._buildSuperAdminItems(context) else ..._buildLoungeAdminItems(context),
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
  }

  Widget _buildLogo(AdminEntity? admin) {
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
                admin?.role == AdminRole.superAdmin ? AppStrings.superAdmin : AppStrings.loungeManager,
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
        icon: Icons.category_outlined,
        label: AppStrings.categories,
        isActive: activeRoute == 'Categories',
        onTap: () {},
      ),
      _SidebarItem(
        icon: Icons.campaign_outlined,
        label: AppStrings.marketing,
        isActive: activeRoute == AppStrings.marketing,
        onTap: () {},
      ),
    ];
  }

  List<Widget> _buildLoungeAdminItems(BuildContext context) {
    return [
      _SidebarItem(
        icon: Icons.sensors,
        label: AppStrings.bookings,
        isActive: activeRoute == AppStrings.bookings,
        onTap: () => context.go(RouterKeys.loungeAdminLiveOps),
      ),
      _SidebarItem(
        icon: Icons.meeting_room_outlined,
        label: AppStrings.rooms,
        isActive: activeRoute == 'Rooms',
        onTap: () => context.go(RouterKeys.loungeAdminRooms),
      ),
      _SidebarItem(
        icon: Icons.restaurant_menu,
        label: AppStrings.extras,
        isActive: activeRoute == 'Extras',
        onTap: () {},
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
