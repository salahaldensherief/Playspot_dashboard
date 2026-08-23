import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/features/staff/data/entities/staff_entity.dart';
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
    if (user?.loungeId != null && user!.loungeId!.isNotEmpty) {
      context.read<StaffCubit>().fetchStaff(user.loungeId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final loungeId = user?.loungeId ?? '';

    return BlocListener<StaffCubit, StaffState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status.isFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? AppStrings.actionFailed),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.staffManagement,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 28.sp, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Manage your lounge team and access levels',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                    ),
                  ],
                ),
                AppButton(
                  text: AppStrings.addStaff,
                  icon: Icons.person_add_outlined,
                  onPressed: () => _showStaffDialog(context, loungeId),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Container(
              width: 400.w, // Fixed width for search to look better
              child: AppTextField(
                hintText: AppStrings.searchStaff,
                prefixIcon: Icons.search,
                onChanged: (val) => context.read<StaffCubit>().setSearchQuery(val),
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: BlocBuilder<StaffCubit, StaffState>(
                builder: (context, state) {
                  if (state.status.isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.neonBlue),
                          SizedBox(height: 16),
                          Text('Loading team members...', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  
                  if (state.staffList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64.r, color: AppColors.textSecondary.withOpacity(0.2)),
                          SizedBox(height: 16.h),
                          Text('No staff members found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp)),
                        ],
                      ),
                    );
                  }

                  final filteredList = state.filteredStaff;
                  
                  if (filteredList.isEmpty && state.searchQuery.isNotEmpty) {
                    return Center(child: Text('No results matching "${state.searchQuery}"', style: const TextStyle(color: AppColors.textSecondary)));
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.mutedBackground),
                          columns: [
                            _buildColumn(AppStrings.fullName),
                            _buildColumn(AppStrings.email),
                            _buildColumn(AppStrings.staffPhone),
                            _buildColumn(AppStrings.roleLabel),
                            _buildColumn(AppStrings.accountStatus),
                            _buildColumn(AppStrings.actions),
                          ],
                          rows: filteredList.map((staff) {
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

  Widget _buildActions(StaffEntity staff, String loungeId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit_outlined, color: AppColors.neonBlue, size: 20.r),
          onPressed: () => _showStaffDialog(context, loungeId, staff: staff),
          tooltip: AppStrings.editStaff,
        ),
        IconButton(
          icon: Icon(staff.isActive ? Icons.block : Icons.check_circle_outline, 
               color: staff.isActive ? AppColors.warning : AppColors.success, size: 20.r),
          onPressed: () => context.read<StaffCubit>().toggleStaffStatus(staff.id, staff.isActive, loungeId),
          tooltip: staff.isActive ? AppStrings.freezeAccount : AppStrings.activate,
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
          onPressed: () => _confirmDelete(staff, loungeId),
          tooltip: AppStrings.delete,
        ),
      ],
    );
  }

  void _showStaffDialog(BuildContext context, String loungeId, {StaffEntity? staff}) {
    final staffCubit = context.read<StaffCubit>();
    showDialog(
      context: context,
      builder: (diagContext) => AddStaffDialog(
        loungeId: loungeId,
        cubit: staffCubit,
        staff: staff,
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
