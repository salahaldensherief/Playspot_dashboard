import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../../../domain/entities/shift_entity.dart';

class ShiftFinancialSummaryTab extends StatelessWidget {
  final ShiftEntity shift;

  const ShiftFinancialSummaryTab({
    super.key,
    required this.shift,
  });

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

  @override
  Widget build(BuildContext context) {
    final discrepancy = shift.calculatedDiscrepancy;
    final isHealthy = discrepancy >= 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
}
