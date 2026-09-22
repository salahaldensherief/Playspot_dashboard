import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../../../domain/entities/cashier_performance_entity.dart';

class CashierPerformanceWidget extends StatelessWidget {
  final List<CashierPerformanceEntity> performances;

  const CashierPerformanceWidget({
    super.key,
    required this.performances,
  });

  @override
  Widget build(BuildContext context) {
    if (performances.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.badge_outlined, size: 40.r, color: AppColors.textSecondary),
              SizedBox(height: 8.h),
              AppText.body(AppStrings.noDataFound, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_pin_rounded, color: AppColors.neonBlue, size: 22.r),
              SizedBox(width: 8.w),
              AppText.heading(AppStrings.cashierPerformanceTitle, fontSize: 16.sp),
            ],
          ),
          SizedBox(height: 16.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.mutedBackground),
              columnSpacing: 16.w,
              columns: [
                DataColumn(label: Text(AppStrings.cashier, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text(AppStrings.cashierShiftCountCol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text(AppStrings.cashierClosedCol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text(AppStrings.cashierApprovedCol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text(AppStrings.cashierTotalSalesCol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text(AppStrings.cashierCashSalesCol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text(AppStrings.cashierDigitalSalesCol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text(AppStrings.cashierExpensesCol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text(AppStrings.cashierDiscrepancyCol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text(AppStrings.cashierAvgSalesCol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              ],
              rows: performances.map((p) {
                final isHealthy = p.totalDifference >= 0;
                return DataRow(cells: [
                  DataCell(Text(p.cashierName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataCell(Text('${p.shiftCount}', style: const TextStyle(color: Colors.white))),
                  DataCell(Text('${p.closedShiftCount}', style: const TextStyle(color: AppColors.textSecondary))),
                  DataCell(Text('${p.approvedShiftCount}', style: const TextStyle(color: AppColors.success))),
                  DataCell(Text('${p.totalSales.toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold))),
                  DataCell(Text('${p.cashSales.toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: AppColors.success))),
                  DataCell(Text('${p.digitalSales.toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: AppColors.warning))),
                  DataCell(Text('${p.totalExpenses.toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: AppColors.danger))),
                  DataCell(Text(
                    '${p.totalDifference.toStringAsFixed(0)} ${AppStrings.egp}',
                    style: TextStyle(color: isHealthy ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text('${p.averageShiftSales.toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: Colors.white))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
