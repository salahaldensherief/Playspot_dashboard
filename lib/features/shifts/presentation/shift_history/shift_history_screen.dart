import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_adaptive_page_header.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_empty_state_widget.dart';
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
  final ScrollController _horizontalScrollController = ScrollController();
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

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  List<ShiftEntity> _applyFilters(List<ShiftEntity> rawShifts) {
    return rawShifts.where((shift) {
      if (_filterStatus == 'open' && shift.status != 'open') return false;
      if (_filterStatus == 'closed' && shift.status != 'closed') return false;
      if (_filterStatus == 'approved' && (!shift.isApproved || shift.status != 'closed')) return false;
      if (_filterStatus == 'unapproved' && (shift.isApproved || shift.status != 'closed')) return false;

      if (_searchQuery.isNotEmpty) {
        final cashier = (shift.cashierName ?? '').toLowerCase();
        if (!cashier.contains(_searchQuery.toLowerCase())) return false;
      }

      if (_filterPeriod != 'all') {
        final now = DateTime.now();
        final start = shift.startTime;
        if (_filterPeriod == 'today') {
          final isSameDay = start.year == now.year && start.month == now.month && start.day == now.day;
          if (!isSameDay) return false;
        } else if (_filterPeriod == 'week') {
          final diffDays = now.difference(start).inDays;
          if (diffDays > 7) return false;
        } else if (_filterPeriod == 'month') {
          final isSameMonth = start.year == now.year && start.month == now.month;
          if (!isSameMonth) return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
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
                title: 'الورديات',
                subtitle: 'سجل الورديات وإغلاق الخزينة',
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
                                loungeId: user?.isStaff == true ? user?.loungeId : null,
                              );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppColors.mutedBackground),
                                dataRowMaxHeight: 60.h,
                                dataRowMinHeight: 48.h,
                                columnSpacing: 20.w,
                                horizontalMargin: 16.w,
                                columns: [
                                  _buildColumn(AppStrings.date),
                                  _buildColumn(AppStrings.closeTime),
                                  _buildColumn(AppStrings.cashier),
                                  _buildColumn(AppStrings.startingCash),
                                  _buildColumn(AppStrings.cashRevenueTitle),
                                  _buildColumn(AppStrings.digitalRevenueTitle),
                                  _buildColumn(AppStrings.expensesAndDrops),
                                  _buildColumn(AppStrings.expectedCash),
                                  _buildColumn(AppStrings.actualCash),
                                  _buildColumn(AppStrings.discrepancy),
                                  _buildColumn(AppStrings.status),
                                  _buildColumn(AppStrings.actions),
                                ],
                                rows: filteredShifts.map((shift) {
                                  final discrepancy = shift.calculatedDiscrepancy;
                                  final isHealthy = discrepancy >= 0;
                                  final user = context.read<LoginCubit>().state.user;
                                  final bool canApprove = context.hasPermission('shifts_approve') || 
                                      user?.isManager == true || 
                                      user?.isLoungeAdmin == true;

                                  final startStr = DateFormat('MMM dd, hh:mm a').format(shift.startTime);
                                  final endStr = shift.endTime != null ? DateFormat('hh:mm a').format(shift.endTime!) : AppStrings.currentShiftOngoing;

                                  return DataRow(cells: [
                                    DataCell(Text(startStr, style: const TextStyle(color: Colors.white))),
                                    DataCell(Text(endStr, style: const TextStyle(color: AppColors.textSecondary))),
                                    DataCell(Text(shift.cashierName ?? AppStrings.system, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    DataCell(Text('${shift.startingCash.toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: Colors.white))),
                                    DataCell(Text('${(shift.cashRevenue ?? 0).toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: AppColors.success))),
                                    DataCell(Text('${(shift.digitalRevenue ?? 0).toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: AppColors.warning))),
                                    DataCell(Text('${(shift.expensesTotal ?? 0).toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: AppColors.danger))),
                                    DataCell(Text('${shift.calculatedExpectedCash.toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: AppColors.neonBlue))),
                                    DataCell(Text(shift.actualCash != null ? '${shift.actualCash!.toStringAsFixed(0)} ${AppStrings.egp}' : '---', style: const TextStyle(color: Colors.white))),
                                    DataCell(
                                      shift.status == 'closed' 
                                      ? Text(
                                          '${discrepancy.toStringAsFixed(0)} ${AppStrings.egp}',
                                          style: TextStyle(color: isHealthy ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold),
                                        )
                                      : const Text('---', style: TextStyle(color: AppColors.textSecondary)),
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
                                          if (shift.status == 'closed' && !shift.isApproved && canApprove) ...[
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
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  DataColumn _buildColumn(String label) {
    return DataColumn(
      label: Text(label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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
              AppText.body(AppStrings.cashierLabelText(shift.cashierName ?? AppStrings.system)),
              AppText.body(AppStrings.cashDiscrepancyLabel('${shift.calculatedDiscrepancy.toStringAsFixed(2)} ${AppStrings.egp}')),
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
