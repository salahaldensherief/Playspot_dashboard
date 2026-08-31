import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/utils/permission_extension.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../domain/entities/shift_entity.dart';
import '../shift_management/shift_cubit.dart';
import '../shift_management/shift_state.dart';

class ShiftHistoryScreen extends StatefulWidget {
  const ShiftHistoryScreen({super.key});

  @override
  State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends State<ShiftHistoryScreen> {
  @override
  void initState() {
    super.initState();
    final user = context.read<LoginCubit>().state.user;
    // If Lounge Staff (Owner or Cashier), only fetch their own lounge shifts
    context.read<ShiftCubit>().fetchShiftHistory(
      loungeId: user?.isStaff == true ? user?.loungeId : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.shiftHistory,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 28.sp, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: BlocBuilder<ShiftCubit, ShiftState>(
              builder: (context, state) {
                if (state.status.isLoading) return const TableShimmer(columns: 7);
                if (state.shifts.isEmpty) return Center(child: Text(AppStrings.noShiftHistoryFound, style: const TextStyle(color: AppColors.textSecondary)));

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(AppColors.mutedBackground),
                        columns: [
                          _buildColumn(AppStrings.date),
                          _buildColumn(AppStrings.cashier),
                          _buildColumn(AppStrings.startingCash),
                          _buildColumn(AppStrings.totalRevenue),
                          _buildColumn(AppStrings.actualCash),
                          _buildColumn(AppStrings.discrepancy),
                          _buildColumn(AppStrings.status),
                          _buildColumn(AppStrings.approveShift),
                        ],
                        rows: state.shifts.map((shift) {
                          final discrepancy = (shift.actualCash ?? 0) - (shift.expectedCash ?? 0);
                          final isHealthy = discrepancy >= 0;
                          final user = context.read<LoginCubit>().state.user;
                          final bool canApprove = context.hasPermission('shifts_approve') || 
                              user?.isManager == true || 
                              user?.isLoungeAdmin == true;

                          return DataRow(cells: [
                            DataCell(Text(DateFormat('MMM dd, hh:mm a').format(shift.startTime), style: const TextStyle(color: Colors.white))),
                            DataCell(Text(shift.cashierName ?? AppStrings.system, style: const TextStyle(color: Colors.white))),
                            DataCell(Text('${shift.startingCash} ${AppStrings.egp}', style: const TextStyle(color: Colors.white))),
                            DataCell(Text('${shift.totalRevenue.toStringAsFixed(2)} ${AppStrings.egp}', style: const TextStyle(color: Colors.white))),
                            DataCell(Text('${shift.actualCash ?? "-"} ${AppStrings.egp}', style: const TextStyle(color: Colors.white))),
                            DataCell(
                              shift.status == 'closed' 
                              ? Text(
                                  '${discrepancy.toStringAsFixed(2)} ${AppStrings.egp}',
                                  style: TextStyle(color: isHealthy ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold),
                                )
                              : const Text('---', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                            DataCell(_buildStatusBadge(shift)),
                            DataCell(
                              shift.status == 'closed' && !shift.isApproved && canApprove
                              ? AppButton(
                                  text: AppStrings.approve,
                                  onPressed: () => _showApproveDialog(context, shift),
                                  height: 30.h,
                                )
                              : shift.isApproved 
                                ? Icon(Icons.check_circle_outline, color: AppColors.success, size: 20.r)
                                : const SizedBox.shrink(),
                            ),
                          ]);
                        }).toList(),
                      ),
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

  Widget _buildStatusBadge(ShiftEntity shift) {
    final isOpen = shift.status == 'open';
    if (isOpen) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.success.withOpacity(0.5)),
        ),
        child: Text(
          shift.status.toUpperCase(),
          style: TextStyle(color: AppColors.success, fontSize: 10.sp, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge.info(shift.status.toUpperCase()),
        SizedBox(height: 4.h),
        if (shift.isApproved)
          StatusBadge.success(AppStrings.approved.toUpperCase())
        else
          StatusBadge.warning(AppStrings.pendingApproval.toUpperCase()),
      ],
    );
  }

  void _showApproveDialog(BuildContext context, ShiftEntity shift) {
    final notesController = TextEditingController();
    final user = context.read<LoginCubit>().state.user;
    final cubit = context.read<ShiftCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 400.w,
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.heading(AppStrings.approveShift, fontSize: 20.sp),
              SizedBox(height: 16.h),
              AppText.body('Shift ID: ${shift.id}'),
              AppText.body('Cashier: ${shift.cashierName}'),
              SizedBox(height: 16.h),
              AppTextField(
                label: AppStrings.managerNotes,
                controller: notesController,
                maxLines: 3,
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(AppStrings.cancel),
                  ),
                  SizedBox(width: 16.w),
                  AppButton(
                    text: AppStrings.approve,
                    onPressed: () {
                      cubit.approveShift(
                        shift.id, 
                        user?.id ?? '', 
                        notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        loungeId: user?.isStaff == true ? user?.loungeId : null,
                      );
                      Navigator.pop(dialogContext);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
