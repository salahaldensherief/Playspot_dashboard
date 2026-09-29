import 'package:flutter/material.dart';
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

    final cardBuilder = mobileCardBuilder;
    if (isMobile && rows.isNotEmpty) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => cardBuilder != null
            ? cardBuilder(context, index)
            : _buildDefaultMobileCard(context, index),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: AppColors.divider),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: availableWidth),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.mutedBackground,
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return AppColors.mutedBackground;
                    }
                    return Colors.transparent;
                  }),
                  dividerThickness: 0.7,
                  horizontalMargin: 20,
                  columnSpacing: 28,
                  headingRowHeight: 52,
                  dataRowMinHeight: 58,
                  dataRowMaxHeight: 84,
                  columns: columns
                      .map(
                        (col) => DataColumn(
                          label: Text(
                            col,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  rows: rows,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultMobileCard(BuildContext context, int index) {
    final row = rows[index];
    final cellCount = row.cells.length < columns.length
        ? row.cells.length
        : columns.length;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            columns.first,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          DefaultTextStyle.merge(
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            child: row.cells.first.child,
          ),
          if (cellCount > 1) ...[
            const Divider(height: 24, color: AppColors.divider),
            for (var cellIndex = 1; cellIndex < cellCount; cellIndex++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: cellIndex == cellCount - 1 ? 0 : 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 104,
                      child: Text(
                        columns[cellIndex],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: row.cells[cellIndex].child,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );

    if (row.onSelectChanged == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => row.onSelectChanged!(true),
        child: card,
      ),
    );
  }
}
