import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_adaptive_page_header.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_empty_state_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
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
import '../shift_management/widgets/shift_kpi_cards.dart';
import '../shift_management/widgets/shift_filters_bar.dart';
import '../shift_management/widgets/shift_details_modal.dart';

class ShiftHistoryScreen extends StatefulWidget {
  const ShiftHistoryScreen({super.key});

  @override
  State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends State<ShiftHistoryScreen> {
  String _filterPeriod = 'all';
  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<LoginCubit>().state.user;
      context.read<ShiftCubit>().fetchShiftHistory(
        loungeId: user?.isStaff == true ? user?.loungeId : null,
      );
    });
  }

  List<ShiftEntity> _applyFilters(List<ShiftEntity> rawShifts) {
    return rawShifts.where((shift) {
      if (_filterStatus == 'open' && shift.status != 'open') return false;
      if (_filterStatus == 'closed' && shift.status != 'closed') return false;
      if (_filterStatus == 'approved' &&
          (!shift.isApproved || shift.status != 'closed')) {
        return false;
      }
      if (_filterStatus == 'unapproved' &&
          (shift.isApproved || shift.status != 'closed')) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final cashier = (shift.cashierName ?? '').toLowerCase();
        if (!cashier.contains(_searchQuery.toLowerCase())) return false;
      }

      if (_filterPeriod != 'all') {
        final now = DateTime.now();
        final start = shift.startTime;
        if (_filterPeriod == 'today') {
          final isSameDay =
              start.year == now.year &&
              start.month == now.month &&
              start.day == now.day;
          if (!isSameDay) return false;
        } else if (_filterPeriod == 'week') {
          final diffDays = now.difference(start).inDays;
          if (diffDays > 7) return false;
        } else if (_filterPeriod == 'month') {
          final isSameMonth =
              start.year == now.year && start.month == now.month;
          if (!isSameMonth) return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    return Padding(
      padding: EdgeInsets.all(isCompact ? 12.r : 24.r),
      child: BlocBuilder<ShiftCubit, ShiftState>(
        builder: (context, state) {
          if (state.status.isLoading && state.shifts.isEmpty) {
            return const TableShimmer(columns: 9);
          }

          final filteredShifts = _applyFilters(state.shifts);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAdaptivePageHeader(
                title: AppStrings.shifts,
                subtitle: AppStrings.shiftsHistorySubtitle,
                primaryAction: AppButton(
                  text: AppStrings.refresh,
                  icon: Icons.refresh,
                  variant: AppButtonVariant.outlined,
                  onPressed: () {
                    final user = context.read<LoginCubit>().state.user;
                    context.read<ShiftCubit>().fetchShiftHistory(
                      loungeId: user?.isStaff == true ? user?.loungeId : null,
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),

              ShiftKpiCards(
                shifts: filteredShifts,
                activeShift: state.activeShift,
              ),

              ShiftFiltersBar(
                onFilterChanged: (period, status, search) {
                  setState(() {
                    _filterPeriod = period;
                    _filterStatus = status;
                    _searchQuery = search;
                  });
                },
              ),

              Expanded(
                child: filteredShifts.isEmpty
                    ? AppEmptyStateWidget(
                        icon: Icons.history_toggle_off_rounded,
                        title: AppStrings.noShiftHistoryFound,
                        actionText: AppStrings.refresh,
                        onActionTextPressed: () {
                          final user = context.read<LoginCubit>().state.user;
                          context.read<ShiftCubit>().fetchShiftHistory(
                            loungeId: user?.isStaff == true
                                ? user?.loungeId
                                : null,
                          );
                        },
                      )
                    : isCompact
                    ? ListView.separated(
                        itemCount: filteredShifts.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 10.h),
                        itemBuilder: (context, index) =>
                            _buildShiftCard(context, filteredShifts[index]),
                      )
                    : _buildShiftTable(context, filteredShifts),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShiftTable(BuildContext context, List<ShiftEntity> shifts) {
    final canApprove = context.hasPermission('shifts_approve');
    return SingleChildScrollView(
      child: DataTableWidget(
        columns: [
          AppStrings.date,
          AppStrings.closeTime,
          AppStrings.cashier,
          AppStrings.startingCash,
          AppStrings.cashRevenueTitle,
          AppStrings.digitalRevenueTitle,
          AppStrings.expensesAndDrops,
          AppStrings.expectedCash,
          AppStrings.actualCash,
          AppStrings.discrepancy,
          AppStrings.status,
          AppStrings.actions,
        ],
        rows: shifts.map((shift) {
          final discrepancy = shift.calculatedDiscrepancy;
          final isHealthy = discrepancy >= 0;
          final startStr = DateFormat(
            'MMM dd, hh:mm a',
          ).format(shift.startTime);
          final endStr = shift.endTime != null
              ? DateFormat('hh:mm a').format(shift.endTime!)
              : AppStrings.currentShiftOngoing;

          return DataRow(
            cells: [
              DataCell(
                Text(
                  startStr,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
              DataCell(
                Text(
                  endStr,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              DataCell(
                Text(
                  shift.cashierName ?? AppStrings.system,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _moneyCell(shift.startingCash, AppColors.textPrimary),
              _moneyCell(shift.cashRevenue ?? 0, AppColors.success),
              _moneyCell(shift.digitalRevenue ?? 0, AppColors.warning),
              _moneyCell(shift.expensesTotal ?? 0, AppColors.danger),
              _moneyCell(shift.calculatedExpectedCash, AppColors.neonBlue),
              DataCell(
                Text(
                  shift.actualCash != null
                      ? '${shift.actualCash!.toStringAsFixed(0)} ${AppStrings.egp}'
                      : AppStrings.notAvailable,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
              DataCell(
                shift.status == 'closed'
                    ? Text(
                        '${discrepancy.toStringAsFixed(0)} ${AppStrings.egp}',
                        style: TextStyle(
                          color: isHealthy
                              ? AppColors.success
                              : AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        AppStrings.notAvailable,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
              ),
              DataCell(_buildStatusBadge(shift)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      text: AppStrings.details,
                      variant: AppButtonVariant.outlined,
                      height: 30.h,
                      onPressed: () => _showDetailsModal(context, shift),
                    ),
                    if (shift.status == 'closed' &&
                        !shift.isApproved &&
                        canApprove) ...[
                      SizedBox(width: 8.w),
                      AppButton(
                        text: AppStrings.approve,
                        height: 30.h,
                        onPressed: () => _showApproveDialog(context, shift),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  DataCell _moneyCell(double amount, Color color) {
    return DataCell(
      Text(
        '${amount.toStringAsFixed(0)} ${AppStrings.egp}',
        style: TextStyle(color: color),
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, ShiftEntity shift) {
    final discrepancy = shift.calculatedDiscrepancy;
    final canApprove = context.hasPermission('shifts_approve');
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMM dd, hh:mm a').format(shift.startTime),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusBadge(shift),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            shift.cashierName ?? AppStrings.system,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Divider(height: 20.h, color: AppColors.borderDefault),
          _shiftValue(AppStrings.cashRevenueTitle, shift.cashRevenue ?? 0),
          _shiftValue(
            AppStrings.digitalRevenueTitle,
            shift.digitalRevenue ?? 0,
          ),
          _shiftValue(AppStrings.expensesAndDrops, shift.expensesTotal ?? 0),
          _shiftValue(AppStrings.expectedCash, shift.calculatedExpectedCash),
          _shiftValue(AppStrings.actualCash, shift.actualCash),
          if (shift.status == 'closed')
            _shiftValue(
              AppStrings.discrepancy,
              discrepancy,
              color: discrepancy >= 0 ? AppColors.success : AppColors.danger,
            ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: AppStrings.details,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => _showDetailsModal(context, shift),
                ),
              ),
              if (shift.status == 'closed' &&
                  !shift.isApproved &&
                  canApprove) ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: AppButton(
                    text: AppStrings.approve,
                    onPressed: () => _showApproveDialog(context, shift),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _shiftValue(String label, double? amount, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            amount == null
                ? AppStrings.notAvailable
                : '${amount.toStringAsFixed(0)} ${AppStrings.egp}',
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ShiftEntity shift) {
    if (shift.status == 'open') {
      return StatusBadge.info(AppStrings.active.toUpperCase());
    }

    if (shift.isApproved) {
      return StatusBadge.success(AppStrings.approved.toUpperCase());
    }

    return StatusBadge.warning(AppStrings.pendingApproval.toUpperCase());
  }

  void _showDetailsModal(BuildContext context, ShiftEntity shift) {
    final cubit = context.read<ShiftCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: ShiftDetailsModal(shift: shift),
      ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          width: 420.w,
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.heading(AppStrings.approveShift, fontSize: 18.sp),
              SizedBox(height: 16.h),
              AppText.body(AppStrings.shiftNumber(shift.id)),
              AppText.body(
                AppStrings.cashierLabelText(
                  shift.cashierName ?? AppStrings.system,
                ),
              ),
              AppText.body(
                AppStrings.cashDiscrepancyLabel(
                  '${shift.calculatedDiscrepancy.toStringAsFixed(2)} ${AppStrings.egp}',
                ),
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: AppStrings.managerNotes,
                hintText: AppStrings.managerNotesPrompt,
                controller: notesController,
                maxLines: 3,
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: AppStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                  SizedBox(width: 12.w),
                  AppButton(
                    text: AppStrings.approve,
                    onPressed: () {
                      cubit.approveShift(
                        shift.id,
                        user?.id ?? '',
                        notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
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
