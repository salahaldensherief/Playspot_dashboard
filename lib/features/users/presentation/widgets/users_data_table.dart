import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import '../cubit/admin_management_cubit.dart';
import '../cubit/admin_management_state.dart';
import 'edit_admin_dialog.dart';

class UsersDataTable extends StatelessWidget {
  final List<UserEntity> admins;
  const UsersDataTable({super.key, required this.admins});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: admins.map((admin) => Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: _buildUserCard(context, admin),
        )).toList(),
      );
    }

    return DataTableWidget(
      columns: [
        AppStrings.fullName,
        AppStrings.email,
        AppStrings.roleLabel,
        AppStrings.referrals,
        AppStrings.pointsBalance,
        AppStrings.status,
        AppStrings.actions,
      ],
      rows: admins.map((admin) => DataRow(
        cells: [
          DataCell(
            Row(
              children: [
                CircleAvatar(
                  radius: 14.r,
                  backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
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
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share_outlined, size: 16.r, color: AppColors.neonBlue),
                SizedBox(width: 6.w),
                AppText.body('${admin.referralCount}', color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ],
            ),
          ),
          DataCell(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, size: 14.r, color: AppColors.warning),
                  SizedBox(width: 4.w),
                  AppText.body('${admin.pointsBalance} ${AppStrings.pointsUnit}', color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12.sp),
                ],
              ),
            ),
          ),
          DataCell(StatusBadge.success(AppStrings.active)),
          DataCell(
            _buildActions(context, admin),
          ),
        ],
      )).toList(),
    );
  }

  Widget _buildUserCard(BuildContext context, UserEntity admin) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
                child: AppText.body(
                  admin.name.isNotEmpty ? admin.name[0].toUpperCase() : '?',
                  color: AppColors.neonPurple,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.body(admin.name, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    AppText.body(admin.email, fontSize: 12.sp),
                  ],
                ),
              ),
              _buildActions(context, admin),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.share_outlined, size: 16.r, color: AppColors.neonBlue),
                  SizedBox(width: 6.w),
                  AppText.body('${AppStrings.referrals}: ${admin.referralCount}', color: AppColors.textSecondary, fontSize: 12.sp),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, size: 14.r, color: AppColors.warning),
                    SizedBox(width: 4.w),
                    AppText.body('${admin.pointsBalance} ${AppStrings.pointsUnit}', color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12.sp),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.body(
                admin.role == UserRole.superAdmin ? AppStrings.superAdmin : AppStrings.loungeManager,
                color: admin.role == UserRole.superAdmin ? AppColors.neonPurple : AppColors.neonBlue,
                fontWeight: FontWeight.bold,
              ),
              StatusBadge.success(AppStrings.active),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, UserEntity admin) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      color: AppColors.cardBackground,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Text(AppStrings.edit, style: const TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
              const SizedBox(width: 12),
              Text(AppStrings.delete, style: const TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          _showEditDialog(context, admin);
        } else if (value == 'delete') {
          _confirmDelete(context, admin.id, admin.name);
        }
      },
    );
  }

  void _confirmDelete(BuildContext context, String adminId, String name) {
    final cubit = context.read<AdminManagementCubit>();
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteWarning} "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagContext), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              cubit.deleteAdmin(adminId);
              Navigator.pop(diagContext);
            }, 
            child: Text(AppStrings.delete, style: const TextStyle(color: AppColors.danger))
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, UserEntity admin) {
    final cubit = context.read<AdminManagementCubit>();
    showDialog(
      context: context,
      builder: (diagContext) => BlocConsumer<AdminManagementCubit, AdminManagementState>(
        bloc: cubit,
        listener: (context, state) {
          if (state.status == AdminManagementStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? AppStrings.error), backgroundColor: AppColors.danger),
            );
          }
        },
        builder: (context, state) {
          return EditAdminDialog(
            admin: admin,
            isLoading: state.status == AdminManagementStatus.loading,
            onSave: (name, email) {
              cubit.updateAdmin(admin.id, name: name, email: email);
              Navigator.pop(diagContext);
            },
          );
        },
      ),
    );
  }
}
