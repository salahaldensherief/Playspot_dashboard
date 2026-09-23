import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/responsive/responsive.dart';
import '../../features/permissions/presentation/cubit/permissions_cubit.dart';
import '../../features/permissions/presentation/cubit/permissions_state.dart';
import '../app_strings.dart';
import '../assets_manager.dart';
import '../theme/app_colors.dart';
import '../widgets/app_dialog.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/auth/presentation/login/login_state.dart';
import 'sidebar/sidebar_item.dart';
import 'sidebar/sidebar_navigation_items.dart';

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
            double sidebarWidth = double.infinity;
            if (Responsive.isDesktop(context)) {
              sidebarWidth = 260.0;
            } else if (Responsive.isTablet(context)) {
              sidebarWidth = 220.0;
            }

            return Container(
              width: sidebarWidth,
              decoration: const BoxDecoration(
                color: AppColors.sidebarBackground,
                border: BorderDirectional(
                    end: BorderSide(color: AppColors.borderDefault)),
              ),
              child: Column(
                children: [
                  SizedBox(height: 24.h),
                  _buildLogo(user),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: SidebarNavigationItems(
                        isSuperAdmin: isSuperAdmin,
                        user: user,
                        activeRoute: activeRoute,
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.borderDefault, height: 1),
                  SidebarItem(
                    icon: Icons.language,
                    label: context.locale.languageCode == 'en'
                        ? 'العربية'
                        : 'English',
                    isActive: false,
                    onTap: () {
                      if (context.locale.languageCode == 'en') {
                        context.setLocale(const Locale('ar'));
                      } else {
                        context.setLocale(const Locale('en'));
                      }
                    },
                  ),
                  SidebarItem(
                    icon: Icons.logout,
                    label: AppStrings.logout,
                    isActive: false,
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                  SizedBox(height: 16.h),
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
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: Image.asset(
                  AssetsManager.logo,
                  width: 32.r,
                  height: 32.r,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.sports_esports,
                    color: AppColors.neonBlue,
                    size: 24.r,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName,
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
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.sp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
