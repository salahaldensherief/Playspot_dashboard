import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import '../cubit/admin_management_cubit.dart';
import '../widgets/users_header.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminManagementCubit>(),
      child: DashboardLayout(
        title: AppStrings.userLabel,
        activeRoute: 'Users',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UsersHeader(),
            SizedBox(height: 32.h),
            const _UsersDataTable(),
          ],
        ),
      ),
    );
  }
}

class _UsersDataTable extends StatelessWidget {
  const _UsersDataTable();

  @override
  Widget build(BuildContext context) {
    return DataTableWidget(
      columns: [AppStrings.fullName, AppStrings.email, 'Role', AppStrings.status, AppStrings.actions],
      rows: [
        DataRow(
          cells: [
            const DataCell(Text('Nexus Manager', style: TextStyle(color: AppColors.textPrimary))),
            const DataCell(Text('lounge@playspot.com', style: TextStyle(color: AppColors.textSecondary))),
            DataCell(Text(AppStrings.loungeManager, style: const TextStyle(color: AppColors.neonBlue))),
            DataCell(Text(AppStrings.active, style: const TextStyle(color: AppColors.success))),
            DataCell(IconButton(icon: const Icon(Icons.more_vert, color: AppColors.textSecondary), onPressed: () {})),
          ],
        ),
      ],
    );
  }
}
