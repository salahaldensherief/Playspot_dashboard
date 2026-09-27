import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/views/lounge_permissions_settings_tab.dart';
import '../widgets/lounge_profile_view.dart';
import '../widgets/lounge_policies_view.dart';

class LoungeProfilePage extends StatelessWidget {
  const LoungeProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final canManagePermissions = user?.isLoungeOwner == true || 
                                user?.isSuperAdmin == true || 
                                user?.isManager == true;

    final tabCount = canManagePermissions ? 3 : 2;

    return DefaultTabController(
      length: tabCount,
      child: DashboardLayout(
        title: AppStrings.loungeProfile,
        activeRoute: AppStrings.loungeProfile,
        isScrollable: false,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.neonBlue,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.neonBlue,
              dividerColor: AppColors.borderDefault,
              tabs: [
                Tab(text: AppStrings.coreInfo),
                Tab(text: AppStrings.loungePoliciesTitle),
                if (canManagePermissions)
                  const Tab(text: 'الصلاحيات - Permissions'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const LoungeProfileView(),
                  const LoungePoliciesView(),
                  if (canManagePermissions)
                    BlocProvider.value(
                      value: sl<PermissionsCubit>(),
                      child: const SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: LoungePermissionsSettingsTab(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
