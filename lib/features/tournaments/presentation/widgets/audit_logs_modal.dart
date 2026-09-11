import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../domain/entities/tournament_audit_log_entity.dart';

class AuditLogsModal extends StatelessWidget {
  final List<TournamentAuditLogEntity> logs;

  const AuditLogsModal({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm:ss');

    return AppDialog(
      title: AppStrings.auditTrail,
      width: 700.w,
      actions: [
        AppButton(
          text: AppStrings.close,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      child: logs.isEmpty
          ? Container(
              padding: EdgeInsets.all(30.r),
              child: Center(
                child: Text(AppStrings.noPromotions, style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: logs.length,
                separatorBuilder: (ctx, i) => const Divider(color: AppColors.borderDefault, height: 1),
                itemBuilder: (ctx, index) {
                  final log = logs[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.neonBlue.withAlpha(30),
                      child: const Icon(Icons.history, color: AppColors.neonBlue, size: 20),
                    ),
                    title: Text(
                      log.actionType,
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('بواسطة: ${log.performedByName ?? log.performedBy}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                        if (log.details != null)
                          Text('التفاصيل: ${log.details}', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
                      ],
                    ),
                    trailing: Text(
                      dateFormat.format(log.createdAt),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
