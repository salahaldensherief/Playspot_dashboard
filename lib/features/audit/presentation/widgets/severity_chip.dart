import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../domain/entities/audit_log_entity.dart';

class SeverityChip extends StatelessWidget {
  final AuditSeverity severity;

  const SeverityChip({super.key, required this.severity});

  Color _getSeverityColor() {
    switch (severity) {
      case AuditSeverity.critical:
        return AppColors.danger;
      case AuditSeverity.warning:
        return AppColors.warning;
      case AuditSeverity.info:
        return AppColors.textSecondary;
    }
  }

  String _getSeverityLabel() {
    switch (severity) {
      case AuditSeverity.critical:
        return AppStrings.severityCritical;
      case AuditSeverity.warning:
        return AppStrings.severityWarning;
      case AuditSeverity.info:
        return AppStrings.severityInfo;
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final color = _getSeverityColor();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            _getSeverityLabel(),
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
