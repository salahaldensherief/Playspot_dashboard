import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/section_container.dart';
import '../../domain/entities/tournament_audit_log_entity.dart';
import 'audit_logs_modal.dart';

class TournamentAuditLogsTab extends StatelessWidget {
  final List<TournamentAuditLogEntity> auditLogs;

  const TournamentAuditLogsTab({
    super.key,
    required this.auditLogs,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: AppStrings.auditTrail,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.auditTrail,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            AppButton(
              text: AppStrings.viewAll,
              variant: AppButtonVariant.outlined,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AuditLogsModal(logs: auditLogs),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 400.h,
          child: ListView.builder(
            itemCount: auditLogs.length,
            itemBuilder: (context, index) {
              final log = auditLogs[index];
              return ListTile(
                title: Text(
                  log.actionType,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                ),
                subtitle: Text(
                  log.performedByName ?? log.performedBy,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
