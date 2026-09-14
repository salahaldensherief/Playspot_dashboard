import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/shifts/domain/entities/shift_entity.dart';
import '../shift_cubit.dart';
import '../shift_state.dart';

class ShiftDetailsModal extends StatefulWidget {
  final ShiftEntity shift;

  const ShiftDetailsModal({
    super.key,
    required this.shift,
  });

  @override
  State<ShiftDetailsModal> createState() => _ShiftDetailsModalState();
}

class _ShiftDetailsModalState extends State<ShiftDetailsModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShiftCubit>().fetchShiftDetails(widget.shift);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 850.w,
        height: 650.h,
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            _buildHeader(context),
            SizedBox(height: 16.h),

            // Tabs Selector
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.neonBlue,
              labelColor: AppColors.neonBlue,
              unselectedLabelColor: AppColors.textSecondary,
              isScrollable: true,
              tabs: [
                Tab(icon: const Icon(Icons.analytics_outlined), text: AppStrings.financialSummaryTab),
                Tab(icon: const Icon(Icons.receipt_long_outlined), text: AppStrings.expensesAndDropsTab),
                Tab(icon: const Icon(Icons.payments_outlined), text: AppStrings.paymentsTab),
                Tab(icon: const Icon(Icons.bookmark_border_rounded), text: AppStrings.linkedBookingsTab),
                Tab(icon: const Icon(Icons.history_edu_rounded), text: AppStrings.auditLogTab),
              ],
            ),
            SizedBox(height: 16.h),

            // Tab Views Content
            Expanded(
              child: BlocBuilder<ShiftCubit, ShiftState>(
                builder: (context, state) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFinancialSummaryTab(widget.shift),
                      _buildExpensesTab(state),
                      _buildPaymentsTab(state),
                      _buildBookingsTab(state),
                      _buildAuditLogsTab(state),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final formattedStart = DateFormat('yyyy-MM-dd hh:mm a').format(widget.shift.startTime);
    final formattedEnd = widget.shift.endTime != null ? DateFormat('yyyy-MM-dd hh:mm a').format(widget.shift.endTime!) : AppStrings.currentShiftOngoing;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.neonBlue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.query_stats_rounded, color: AppColors.neonBlue, size: 24.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppText.heading(AppStrings.shiftDetailsTitle(widget.shift.id), fontSize: 18.sp),
                  SizedBox(width: 12.w),
                  widget.shift.status == 'open'
                      ? StatusBadge.info(AppStrings.open)
                      : widget.shift.isApproved
                          ? StatusBadge.success(AppStrings.approved)
                          : StatusBadge.warning(AppStrings.pendingApproval),
                ],
              ),
              SizedBox(height: 4.h),
              AppText.body(
                AppStrings.shiftFromTo(widget.shift.cashierName ?? AppStrings.system, formattedStart, formattedEnd),
                color: AppColors.textSecondary,
                fontSize: 12.sp,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFinancialSummaryTab(ShiftEntity shift) {
    final discrepancy = shift.calculatedDiscrepancy;
    final isHealthy = discrepancy >= 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Grid
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 2.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSummaryItem(AppStrings.startingCash, '${shift.startingCash.toStringAsFixed(2)} ${AppStrings.egp}', AppColors.textPrimary),
              _buildSummaryItem(AppStrings.cashRevenueTitle, '${(shift.cashRevenue ?? 0).toStringAsFixed(2)} ${AppStrings.egp}', AppColors.success),
              _buildSummaryItem(AppStrings.digitalRevenueTitle, '${(shift.digitalRevenue ?? 0).toStringAsFixed(2)} ${AppStrings.egp}', AppColors.warning),
              _buildSummaryItem(AppStrings.totalSales, '${shift.totalRevenue.toStringAsFixed(2)} ${AppStrings.egp}', AppColors.neonBlue),
              _buildSummaryItem(AppStrings.expensesAndDrops, '${(shift.expensesTotal ?? 0).toStringAsFixed(2)} ${AppStrings.egp}', AppColors.danger),
              _buildSummaryItem(AppStrings.expectedCashDrawer, '${shift.calculatedExpectedCash.toStringAsFixed(2)} ${AppStrings.egp}', AppColors.neonBlue),
              _buildSummaryItem(AppStrings.actualCashCounted, shift.actualCash != null ? '${shift.actualCash!.toStringAsFixed(2)} ${AppStrings.egp}' : AppStrings.notClosedYet, AppColors.textPrimary),
              _buildSummaryItem(AppStrings.financialDiscrepancy, '${discrepancy.toStringAsFixed(2)} ${AppStrings.egp}', isHealthy ? AppColors.success : AppColors.danger),
            ],
          ),
          SizedBox(height: 20.h),

          // Discrepancy Alert Banner
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: (isHealthy ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isHealthy ? AppColors.success : AppColors.danger),
            ),
            child: Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle_outline : Icons.error_outline,
                  color: isHealthy ? AppColors.success : AppColors.danger,
                  size: 28.r,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body(
                        isHealthy ? AppStrings.healthyFinancialStatus : AppStrings.deficitWarningStatus,
                        fontWeight: FontWeight.bold,
                        color: isHealthy ? AppColors.success : AppColors.danger,
                      ),
                      SizedBox(height: 2.h),
                      AppText.body(
                        AppStrings.discrepancyValue('${discrepancy.toStringAsFixed(2)} ${AppStrings.egp}'),
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Notes Section
          if (shift.notes != null && shift.notes!.isNotEmpty) ...[
            AppText.body(AppStrings.cashierNotesTitle, fontWeight: FontWeight.bold),
            SizedBox(height: 4.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.mutedBackground,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: AppText.body(shift.notes!, color: AppColors.textSecondary),
            ),
            SizedBox(height: 12.h),
          ],
          if (shift.managerNotes != null && shift.managerNotes!.isNotEmpty) ...[
            AppText.body(AppStrings.approvedManagerNotesTitle, fontWeight: FontWeight.bold),
            SizedBox(height: 4.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.mutedBackground,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: AppText.body(shift.managerNotes!, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText.body(label, color: AppColors.textSecondary, fontSize: 11.sp),
          SizedBox(height: 4.h),
          AppText.body(value, color: color, fontWeight: FontWeight.bold, fontSize: 14.sp),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(ShiftState state) {
    if (state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48.r, color: AppColors.textSecondary),
            SizedBox(height: 12.h),
            AppText.body(AppStrings.noExpensesRecorded, color: AppColors.textSecondary),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: state.expenses.length,
      separatorBuilder: (context, index) => Divider(color: AppColors.borderDefault, height: 1.h),
      itemBuilder: (context, index) {
        final item = state.expenses[index];
        final isDrop = item.isCashDrop;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: (isDrop ? AppColors.warning : AppColors.danger).withValues(alpha: 0.15),
            child: Icon(
              isDrop ? Icons.move_to_inbox : Icons.receipt_long,
              color: isDrop ? AppColors.warning : AppColors.danger,
              size: 20.r,
            ),
          ),
          title: Text(item.reason, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${DateFormat('hh:mm a').format(item.createdAt)} | ${AppStrings.byUser(item.createdByName ?? AppStrings.system)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: Text(
            '${item.amount.toStringAsFixed(2)} ${AppStrings.egp}',
            style: TextStyle(
              color: isDrop ? AppColors.warning : AppColors.danger,
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab(ShiftState state) {
    if (state.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments_outlined, size: 48.r, color: AppColors.textSecondary),
            SizedBox(height: 12.h),
            AppText.body(AppStrings.noPaymentsRecorded, color: AppColors.textSecondary),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: state.payments.length,
      separatorBuilder: (context, index) => Divider(color: AppColors.borderDefault, height: 1.h),
      itemBuilder: (context, index) {
        final item = state.payments[index];
        final isCash = item.isCash;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: (isCash ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
            child: Icon(
              isCash ? Icons.money : Icons.credit_card,
              color: isCash ? AppColors.success : AppColors.warning,
              size: 20.r,
            ),
          ),
          title: Text(AppStrings.paymentItem(item.category), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${AppStrings.paymentMethodLabel(item.paymentMethod.toUpperCase())} | ${DateFormat('hh:mm a').format(item.createdAt)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: Text(
            '${item.amount.toStringAsFixed(2)} ${AppStrings.egp}',
            style: TextStyle(
              color: isCash ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsTab(ShiftState state) {
    if (state.shiftBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 48.r, color: AppColors.textSecondary),
            SizedBox(height: 12.h),
            AppText.body(AppStrings.noLinkedBookings, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: state.shiftBookings.length,
      separatorBuilder: (context, index) => Divider(color: AppColors.borderDefault, height: 1.h),
      itemBuilder: (context, index) {
        final b = state.shiftBookings[index];
        final customerName = b['profiles']?['full_name']?.toString() ?? AppStrings.walkInCustomer;
        final roomName = b['rooms']?['name']?.toString() ?? AppStrings.rooms;
        final price = (b['total_price'] ?? b['price'] ?? 0).toDouble();

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.neonBlue.withValues(alpha: 0.15),
            child: Icon(Icons.videogame_asset, color: AppColors.neonBlue, size: 20.r),
          ),
          title: Text('$customerName ($roomName)', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${AppStrings.statusLabel(b['status']?.toString() ?? "N/A")} | ${AppStrings.paymentStatusLabel(b['payment_status']?.toString() ?? "N/A")}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: Text(
            '${price.toStringAsFixed(2)} ${AppStrings.egp}',
            style: const TextStyle(
              color: AppColors.neonBlue,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogsTab(ShiftState state) {
    if (state.auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu_rounded, size: 48.r, color: AppColors.textSecondary),
            SizedBox(height: 12.h),
            AppText.body(AppStrings.noDataFound, color: AppColors.textSecondary),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: state.auditLogs.length,
      separatorBuilder: (context, index) => Divider(color: AppColors.borderDefault, height: 1.h),
      itemBuilder: (context, index) {
        final log = state.auditLogs[index];
        final actionColor = log.action == 'insert' 
            ? AppColors.success 
            : log.action == 'update' 
                ? AppColors.warning 
                : AppColors.danger;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: actionColor.withValues(alpha: 0.15),
            child: Icon(
              log.action == 'insert' 
                  ? Icons.add_circle_outline 
                  : log.action == 'update' 
                      ? Icons.edit_note_rounded 
                      : Icons.delete_outline,
              color: actionColor,
              size: 20.r,
            ),
          ),
          title: Text(
            '${log.entityType.toUpperCase()} - ${log.action.toUpperCase()}',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${DateFormat('yyyy-MM-dd hh:mm:ss a').format(log.createdAt)} | ${AppStrings.byUser(log.actorName ?? AppStrings.system)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        );
      },
    );
  }
}
