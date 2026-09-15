import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../domain/entities/tournament_audit_log_entity.dart';

String formatAuditActionType(String raw) {
  final clean = raw.trim().toLowerCase();
  if (clean.isEmpty) return 'تحديث في إعدادات البطولة';
  switch (clean) {
    case 'create':
    case 'tournament_created':
    case 'created':
      return 'إنشاء مسودة البطولة';
    case 'update':
    case 'tournament_updated':
    case 'updated':
      return 'تعديل بيانات البطولة';
    case 'publish':
    case 'tournament_published':
    case 'published':
      return 'نشر البطولة للتسجيل';
    case 'cancel':
    case 'tournament_cancelled':
    case 'cancelled':
      return 'إلغاء البطولة';
    case 'payment_approved':
    case 'approve_payment':
      return 'اعتماد إيصال دفع اللاعب';
    case 'payment_rejected':
    case 'reject_payment':
      return 'رفض إيصال دفع اللاعب';
    case 'cash_payment':
    case 'cash_payment_recorded':
      return 'تسجيل دفع نقدي بمقر الصالة';
    case 'check_in':
    case 'participant_checked_in':
      return 'تسجيل حضور وتأكيد لاعب';
    case 'draw_bracket':
    case 'bracket_drawn':
      return 'توليد وسحب قرعة البطولة';
    case 'match_started':
    case 'start_match':
      return 'بدء مباراة جديدة';
    case 'resolve_dispute':
    case 'dispute_resolved':
      return 'حل نزاع مباراة وتحديد الفائز';
    case 'complete':
    case 'tournament_completed':
      return 'إكمال البطولة وتوزيع الجوائز';
    default:
      return raw.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }
}

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_toggle_off_rounded, color: AppColors.textSecondary, size: 40),
                    SizedBox(height: 12.h),
                    Text(
                      'لا توجد سجلات تتبع لهذه البطولة حتى الآن',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                    ),
                  ],
                ),
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
                  final performer = log.performedByName ?? (log.performedBy.isNotEmpty ? log.performedBy : 'النظام');

                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.neonBlue.withAlpha(30),
                      child: const Icon(Icons.history, color: AppColors.neonBlue, size: 20),
                    ),
                    title: Text(
                      formatAuditActionType(log.actionType),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4.h),
                        Text(
                          'بواسطة: $performer',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                        ),
                        if (log.details != null && log.details!.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            'التفاصيل: ${log.details}',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    trailing: Text(
                      dateFormat.format(log.createdAt.toLocal()),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
