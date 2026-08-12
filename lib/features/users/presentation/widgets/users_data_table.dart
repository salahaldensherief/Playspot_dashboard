import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import '../cubit/admin_management_cubit.dart';

class UsersDataTable extends StatelessWidget {
  final List<UserEntity> admins;
  const UsersDataTable({super.key, required this.admins});

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
                  _confirmDelete(context, admin.id, admin.name);
                }
              },
            ),
          ),
        ],
      )).toList(),
    );
  }

  void _confirmDelete(BuildContext context, String adminId, String name) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation, style: TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteWarning} "$name"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagContext), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              context.read<AdminManagementCubit>().deleteAdmin(adminId);
              Navigator.pop(diagContext);
            }, 
            child: Text(AppStrings.delete, style: const TextStyle(color: AppColors.danger))
          ),
        ],
      ),
    );
  }
}
