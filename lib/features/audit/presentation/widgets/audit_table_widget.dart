import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/data_table_widget.dart';
import '../../domain/entities/audit_log_entity.dart';
import 'audit_event_details_dialog.dart';
import 'severity_chip.dart';

class AuditTableWidget extends StatelessWidget {
  final List<AuditLogEntity> logs;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const AuditTableWidget({
    super.key,
    required this.logs,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
            hasMore &&
            !isLoadingMore) {
          onLoadMore();
        }
        return false;
      },
      child: Column(
        children: [
          DataTableWidget(
            columns: [
              AppStrings.eventId,
              AppStrings.sentDate,
              AppStrings.entityType,
              AppStrings.action,
              AppStrings.actor,
              AppStrings.severity,
              AppStrings.view,
            ],
            rows: logs.map((log) {
              return DataRow(
                onSelectChanged: (_) {
                  showDialog(
                    context: context,
                    builder: (_) => AuditEventDetailsDialog(event: log),
                  );
                },
                cells: [
                  DataCell(
                    Text(
                      log.id.length > 8 ? log.id.substring(0, 8) : log.id,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                        fontFamily: 'Monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatDateTime(log.createdAt),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.mutedBackground,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        log.entityType.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.neonBlue,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      log.action.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      log.actorName ?? log.actorUserId ?? 'System',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp),
                    ),
                  ),
                  DataCell(
                    SeverityChip(severity: log.severity),
                  ),
                  DataCell(
                    IconButton(
                      icon: Icon(Icons.visibility_outlined, size: 18.r, color: AppColors.neonBlue),
                      tooltip: AppStrings.eventDetails,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AuditEventDetailsDialog(event: log),
                        );
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          if (isLoadingMore) ...[
            SizedBox(height: 16.h),
            Center(
              child: SizedBox(
                width: 24.r,
                height: 24.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.neonBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
