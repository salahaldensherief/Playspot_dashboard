import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../domain/entities/audit_log_entity.dart';
import 'audit_event_details_dialog.dart';
import 'severity_chip.dart';

class AuditMobileList extends StatelessWidget {
  final List<AuditLogEntity> logs;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const AuditMobileList({
    super.key,
    required this.logs,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd/MM HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
            hasMore &&
            !isLoadingMore) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (ctx, i) => SizedBox(height: 10.h),
        itemBuilder: (ctx, index) {
          if (index >= logs.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.neonBlue,
                  ),
                ),
              ),
            );
          }

          final log = logs[index];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AuditEventDetailsDialog(event: log),
                );
              },
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.mutedBackground,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            log.entityType.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.neonBlue,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            log.action.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SeverityChip(severity: log.severity),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 14.r, color: AppColors.textSecondary),
                            SizedBox(width: 4.w),
                            Text(
                              log.actorName ?? log.actorUserId ?? 'System',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12.sp),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 14.r, color: AppColors.textSecondary),
                            SizedBox(width: 4.w),
                            Text(
                              _formatDateTime(log.createdAt),
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11.sp),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
