import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import '../cubit/admin_management_cubit.dart';
import '../cubit/admin_management_state.dart';
import '../widgets/users_header.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminManagementCubit>()..fetchAdmins(),
      child: DashboardLayout(
        title: AppStrings.userLabel,
        activeRoute: 'Users',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UsersHeader(),
            SizedBox(height: 32.h),
            const _UsersTableSection(),
          ],
        ),
      ),
    );
  }
}

class _UsersTableSection extends StatelessWidget {
  const _UsersTableSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminManagementCubit, AdminManagementState>(
      builder: (context, state) {
        if (state is AdminManagementLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }
        if (state is AdminManagementError) {
          return Center(child: AppText.body(state.message, color: AppColors.danger));
        }
        if (state is AdminManagementLoaded) {
          return _UsersDataTable(admins: state.admins);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _UsersDataTable extends StatelessWidget {
  final List<UserEntity> admins;
  const _UsersDataTable({required this.admins});

  @override
  Widget build(BuildContext context) {
    return DataTableWidget(
      columns: [AppStrings.fullName, AppStrings.email, 'Role', AppStrings.status, AppStrings.actions],
      rows: admins.map((admin) => DataRow(
        cells: [
          DataCell(
            Row(
              children: [
                CircleAvatar(
                  radius: 14.r,
                  backgroundColor: AppColors.neonPurple.withOpacity(0.2),
                  child: AppText.body(
                    admin.name.isNotEmpty ? admin.name[0].toUpperCase() : '?',
                    color: AppColors.neonPurple,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                AppText.body(admin.name, color: AppColors.textPrimary),
              ],
            ),
          ),
          DataCell(AppText.body(admin.email, color: AppColors.textSecondary)),
          DataCell(
            AppText.body(
              admin.role == UserRole.superAdmin ? AppStrings.superAdmin : AppStrings.loungeManager,
              color: admin.role == UserRole.superAdmin ? AppColors.neonPurple : AppColors.neonBlue,
            ),
          ),
          DataCell(StatusBadge.success(AppStrings.active)),
          DataCell(
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              color: AppColors.cardBackground,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                      SizedBox(width: 12),
                      Text('Edit Admin', style: TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                      SizedBox(width: 12),
                      Text('Delete Account', style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDelete(context, admin.name);
                }
              },
            ),
          ),
        ],
      )).toList(),
    );
  }

  void _confirmDelete(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Delete Administrator', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Delete', style: TextStyle(color: AppColors.danger))
          ),
        ],
      ),
    );
  }
}
