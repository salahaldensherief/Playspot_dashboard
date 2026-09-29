import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../domain/entities/audit_log_entity.dart';
import 'severity_chip.dart';

class AuditEventDetailsDialog extends StatelessWidget {
  final AuditLogEntity event;

  const AuditEventDetailsDialog({super.key, required this.event});

  void _copyEventId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: event.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.eventIdCopied),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy/MM/dd - hh:mm:ss a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final changes = event.changes;

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Container(
        width: 600.w,
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.event_note_rounded, color: AppColors.neonBlue, size: 24.r),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    AppStrings.eventDetails,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SeverityChip(severity: event.severity),
                SizedBox(width: 8.w),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20.r),
                  tooltip: AppStrings.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(color: AppColors.borderDefault, height: 24.h),

            // Info Grid: Actor, Date, Event ID
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.mutedBackground,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    label: AppStrings.actor,
                    value: event.actorName ?? event.actorUserId ?? 'N/A',
                    subtitle: event.actorRole,
                    icon: Icons.person_outline_rounded,
                  ),
                  SizedBox(height: 8.h),
                  _buildDetailRow(
                    label: AppStrings.sentDate,
                    value: _formatDateTime(event.createdAt),
                    icon: Icons.access_time_rounded,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.key_rounded, size: 16.r, color: AppColors.textSecondary),
                      SizedBox(width: 8.w),
                      Text(
                        '${AppStrings.eventId}: ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                      ),
                      Expanded(
                        child: Text(
                          event.id,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.sp,
                            fontFamily: 'Monospace',
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Tooltip(
                        message: AppStrings.copyEventId,
                        child: InkWell(
                          onTap: () => _copyEventId(context),
                          borderRadius: BorderRadius.circular(4.r),
                          child: Padding(
                            padding: EdgeInsets.all(4.r),
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 14.r, color: AppColors.neonBlue),
                                SizedBox(width: 4.w),
                                Text(
                                  AppStrings.copyEventId,
                                  style: TextStyle(
                                    color: AppColors.neonBlue,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Reason
            Text(
              AppStrings.reason,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              (event.reason != null && event.reason!.trim().isNotEmpty)
                  ? event.reason!
                  : AppStrings.noReasonProvided,
              style: TextStyle(
                color: (event.reason != null && event.reason!.trim().isNotEmpty)
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 16.h),

            // What changed (old -> new)
            if (changes.isNotEmpty) ...[
              Text(
                AppStrings.fieldChanges,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 200.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: changes.length,
                  separatorBuilder: (ctx, i) => SizedBox(height: 6.h),
                  itemBuilder: (ctx, i) {
                    final change = changes[i];
                    return Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.mutedBackground,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              change.labelKey,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${change.oldValue ?? "N/A"}',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 11.sp,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded, size: 14.r, color: AppColors.textSecondary),
                          SizedBox(width: 4.w),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${change.newValue ?? "N/A"}',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            SizedBox(height: 20.h),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                text: AppStrings.close,
                onPressed: () => Navigator.of(context).pop(),
                variant: AppButtonVariant.outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.r, color: AppColors.textSecondary),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
        ),
        Text(
          value,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          SizedBox(width: 6.w),
          Text(
            '($subtitle)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
          ),
        ],
      ],
    );
  }
}
