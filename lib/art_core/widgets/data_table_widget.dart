import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class DataTableWidget extends StatelessWidget {
  final List<String> columns;
  final List<DataRow> rows;

  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: AppColors.divider,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 310.w),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(AppColors.mutedBackground),
              horizontalMargin: 24.w,
              columnSpacing: 20.w,
              headingRowHeight: 56.h,
              dataRowHeight: 64.h,
              columns: columns
                  .map((col) => DataColumn(
                        label: Text(
                          col,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ))
                  .toList(),
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }
}
