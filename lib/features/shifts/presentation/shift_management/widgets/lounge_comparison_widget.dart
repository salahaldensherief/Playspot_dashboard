import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../../../domain/entities/lounge_comparison_entity.dart';

class LoungeComparisonWidget extends StatelessWidget {
  final List<LoungeComparisonEntity> comparisons;

  const LoungeComparisonWidget({
    super.key,
    required this.comparisons,
  });

  @override
  Widget build(BuildContext context) {
    if (comparisons.isEmpty) {
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
              Icon(Icons.store_mall_directory_outlined, size: 40.r, color: AppColors.textSecondary),
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
              Icon(Icons.compare_arrows_rounded, color: AppColors.neonBlue, size: 22.r),
              SizedBox(width: 8.w),
              AppText.heading(AppStrings.loungeComparisonTitle, fontSize: 16.sp),
            ],
          ),
          SizedBox(height: 16.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.mutedBackground),
              columnSpacing: 20.w,
              columns: [
                DataColumn(label: Text(AppStrings.loungeName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text('إجمالي الورديات', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text('مفتوحة حالياً', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text('إجمالي المبيعات', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text('إجمالي المصروفات', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text('إجمالي الفروقات', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text('متوسط مبيعات الوردية', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                DataColumn(label: Text('بانتظار الاعتماد', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              ],
              rows: comparisons.map((c) {
                final isHealthy = c.totalDifference >= 0;
                return DataRow(cells: [
                  DataCell(Text(c.loungeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataCell(Text('${c.shiftCount}', style: const TextStyle(color: Colors.white))),
                  DataCell(Text('${c.openShiftCount}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))),
                  DataCell(Text('${c.totalSales.toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold))),
                  DataCell(Text('${c.totalExpenses.toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: AppColors.danger))),
                  DataCell(Text(
                    '${c.totalDifference.toStringAsFixed(0)} ${AppStrings.egp}',
                    style: TextStyle(color: isHealthy ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text('${c.averageShiftSales.toStringAsFixed(0)} ${AppStrings.egp}', style: const TextStyle(color: Colors.white))),
                  DataCell(Text('${c.pendingApprovalCount}', style: const TextStyle(color: AppColors.warning))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
