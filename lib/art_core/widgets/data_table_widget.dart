import 'package:flutter/material.dart';
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(AppColors.mutedBackground),
        columns: columns
            .map((col) => DataColumn(
                  label: Text(
                    col,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ))
            .toList(),
        rows: rows,
      ),
    );
  }
}
