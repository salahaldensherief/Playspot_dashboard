import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/shifts/domain/entities/shift_entity.dart';
import '../shift_cubit.dart';
import 'shift_audit_logs_tab.dart';
import 'shift_bookings_tab.dart';
import 'shift_expenses_tab.dart';
import 'shift_financial_summary_tab.dart';
import 'shift_modal_header.dart';
import 'shift_payments_tab.dart';

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
            ShiftModalHeader(shift: widget.shift),
            SizedBox(height: 16.h),
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
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ShiftFinancialSummaryTab(shift: widget.shift),
                  const ShiftExpensesTab(),
                  const ShiftPaymentsTab(),
                  const ShiftBookingsTab(),
                  const ShiftAuditLogsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
