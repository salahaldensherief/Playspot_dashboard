import 'audit_labels.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_section_header.dart';
import '../../../../core/di/di.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../../domain/usecases/get_timeline_logs_usecase.dart';
import 'audit_event_details_dialog.dart';
import 'severity_chip.dart';

class AuditTimeline extends StatefulWidget {
  final String entityType;
  final String entityId;
  final String? loungeId;

  const AuditTimeline({
    super.key,
    required this.entityType,
    required this.entityId,
    this.loungeId,
  });

  @override
  State<AuditTimeline> createState() => _AuditTimelineState();
}

class _AuditTimelineState extends State<AuditTimeline> {
  int _fetchGeneration = 0;
  bool _isLoading = true;
  List<AuditLogEntity> _logs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTimeline();
  }

  @override
  void didUpdateWidget(covariant AuditTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entityId != widget.entityId ||
        oldWidget.entityType != widget.entityType ||
        oldWidget.loungeId != widget.loungeId) {
      _fetchTimeline();
    }
  }

  Future<void> _fetchTimeline() async {
    final generation = ++_fetchGeneration;
    setState(() {
      _isLoading = true;
      _error = null;
      _logs = [];
    });

    final effectiveLoungeId =
        widget.loungeId ??
        context.read<LoginCubit>().state.user?.loungeId ??
        '';

    final usecase = sl<GetTimelineLogsUsecase>();
    final result = await usecase(
      GetTimelineLogsParams(
        loungeId: effectiveLoungeId,
        entityType: widget.entityType,
        entityId: widget.entityId,
      ),
    );

    if (!mounted || generation != _fetchGeneration) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _error = failure.message;
      }),
      (logs) => setState(() {
        _isLoading = false;
        _logs = logs;
      }),
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MM/dd HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSectionHeader(
            title: AppStrings.auditTimeline,
            icon: Icons.timeline_rounded,
            iconColor: AppColors.neonBlue,
          ),
          SizedBox(height: 12.h),

          if (_isLoading) ...[
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.neonBlue,
                  ),
                ),
              ),
            ),
          ] else if (_error != null) ...[
            Center(
              child: Column(
                children: [
                  Text(
                    (_error ?? '').tr(),
                    style: TextStyle(color: AppColors.danger, fontSize: 12.sp),
                  ),
                  SizedBox(height: 6.h),
                  AppButton(
                    text: AppStrings.retry,
                    icon: Icons.refresh,
                    variant: AppButtonVariant.text,
                    foregroundColor: AppColors.neonBlue,
                    onPressed: _fetchTimeline,
                  ),
                ],
              ),
            ),
          ] else if (_logs.isEmpty) ...[
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  AppStrings.noAuditLogs,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logs.length,
              separatorBuilder: (ctx, i) =>
                  Divider(color: AppColors.borderDefault, height: 16.h),
              itemBuilder: (ctx, index) {
                final item = _logs[index];
                return InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AuditEventDetailsDialog(event: item),
                  ),
                  borderRadius: BorderRadius.circular(6.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 4.h,
                      horizontal: 6.w,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 14.r,
                          backgroundColor: AppColors.mutedBackground,
                          child: Icon(
                            Icons.history_rounded,
                            size: 16.r,
                            color: AppColors.neonBlue,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auditActionLabel(item.action),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${item.actorName ?? item.actorUserId ?? 'system_actor'.tr()} • ${_formatDateTime(item.createdAt)}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SeverityChip(severity: item.severity),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18.r,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
