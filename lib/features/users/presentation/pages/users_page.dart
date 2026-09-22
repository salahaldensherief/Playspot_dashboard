import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import '../cubit/admin_management_cubit.dart';
import '../widgets/users_header.dart';
import '../widgets/users_stats_grid.dart';
import '../widgets/users_table_section.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminManagementCubit>().fetchAdmins();
    context.read<LoungeCubit>().fetchLounges();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: AppStrings.userLabel,
      activeRoute: RouterKeys.superAdminUsers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const UsersHeader(),
          SizedBox(height: 24.h),
          const UsersStatsGrid(),
          SizedBox(height: 24.h),
          const UsersTableSection(),
        ],
      ),
    );
  }
}
