import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/core/responsive/app_breakpoints.dart';
import '../theme/app_colors.dart';

class DataTableWidget extends StatelessWidget {
  final List<String> columns;
  final List<DataRow> rows;
  final Widget Function(BuildContext context, int index)? mobileCardBuilder;

  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.mobileCardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile && mobileCardBuilder != null && rows.isNotEmpty) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) => mobileCardBuilder!(context, index),
      );
    }

    return Container(
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
            constraints: BoxConstraints(
              minWidth: isMobile
                  ? MediaQuery.sizeOf(context).width - 32.w
                  : MediaQuery.sizeOf(context).width - 310.w,
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.mutedBackground),
              horizontalMargin: 16.w,
              columnSpacing: 16.w,
              headingRowHeight: 52.h,
              dataRowMinHeight: 60.h,
              dataRowMaxHeight: 80.h,
              columns: columns
                  .map((col) => DataColumn(
                        label: Text(
                          col,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
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
