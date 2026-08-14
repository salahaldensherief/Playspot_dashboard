import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_cubit.dart';
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_state.dart';
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/widgets/add_staff_dialog.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  void initState() {
    super.initState();
    final user = context.read<LoginCubit>().state.user;
    if (user?.loungeId != null) {
      context.read<StaffCubit>().fetchStaff(user!.loungeId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.staffManagement,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 28.sp, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
              ),
              AppButton(
                text: AppStrings.addStaff,
                icon: Icons.person_add_outlined,
                onPressed: () => _showAddStaffDialog(context, loungeId),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: BlocBuilder<StaffCubit, StaffState>(
              builder: (context, state) {
                if (state.status.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
                if (state.staffList.isEmpty) return const Center(child: Text('No staff members found', style: TextStyle(color: AppColors.textSecondary)));

                return Container(
                  key: ValueKey('staff_table_${state.staffList.length}'), // Key يجبر الجدول على التحديث
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: SingleChildScrollView(
                      child: DataTable(
                        key: UniqueKey(), // أمان إضافي لإعادة الرسم
                        headingRowColor: MaterialStateProperty.all(AppColors.mutedBackground),
                        columns: [
                          _buildColumn(AppStrings.fullName),
                          _buildColumn(AppStrings.email),
                          _buildColumn(AppStrings.staffPhone),
                          _buildColumn(AppStrings.roleLabel),
                          _buildColumn(AppStrings.accountStatus),
                          _buildColumn(AppStrings.actions),
                        ],
                        rows: state.staffList.map((staff) {
                          return DataRow(cells: [
                            DataCell(Text(staff.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                            DataCell(Text(staff.email, style: const TextStyle(color: AppColors.textSecondary))),
                            DataCell(Text(staff.phone ?? 'N/A', style: const TextStyle(color: AppColors.textSecondary))),
                            DataCell(_buildRoleBadge(staff.role)),
                            DataCell(_buildStatusBadge(staff.isActive)),
                            DataCell(_buildActions(staff, loungeId)),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _buildColumn(String label) {
    return DataColumn(
      label: Text(label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp)),
    );
  }

  Widget _buildRoleBadge(String role) {
    if (role == 'lounge_owner') return StatusBadge.secondary(AppStrings.manager);
    if (role == 'manager') return StatusBadge.secondary(AppStrings.manager);
    return StatusBadge.info(AppStrings.cashierLabel);
  }

  Widget _buildStatusBadge(bool isActive) {
    return isActive 
        ? StatusBadge.success(AppStrings.active) 
        : StatusBadge.danger(AppStrings.freezeAccount);
  }

  Widget _buildActions(dynamic staff, String loungeId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(staff.isActive ? Icons.block : Icons.check_circle_outline, 
               color: staff.isActive ? AppColors.warning : AppColors.success, size: 20.r),
          onPressed: () => context.read<StaffCubit>().toggleStaffStatus(staff.id, staff.isActive, loungeId),
          tooltip: staff.isActive ? AppStrings.freezeAccount : 'Activate',
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
          onPressed: () => _confirmDelete(staff, loungeId),
          tooltip: AppStrings.delete,
        ),
      ],
    );
  }

  void _showAddStaffDialog(BuildContext context, String loungeId) {
    final staffCubit = context.read<StaffCubit>();
    showDialog(
      context: context,
      builder: (diagContext) => AddStaffDialog(
        loungeId: loungeId,
        cubit: staffCubit,
      ),
    );
  }

  void _confirmDelete(dynamic staff, String loungeId) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteStaffWarning} (${staff.name})'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagContext), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              context.read<StaffCubit>().deleteStaff(staff.id, loungeId);
              Navigator.pop(diagContext);
            }, 
            child: Text(AppStrings.delete, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
