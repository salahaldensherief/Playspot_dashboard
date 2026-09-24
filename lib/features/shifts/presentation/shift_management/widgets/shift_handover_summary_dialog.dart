import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/shifts/domain/entities/shift_entity.dart';

class ShiftHandoverSummaryDialog extends StatelessWidget {
  final ShiftEntity shift;

  const ShiftHandoverSummaryDialog({super.key, required this.shift});

  @override
  Widget build(BuildContext context) {
    final actual = shift.actualCash ?? 0.0;
    final expected = shift.expectedCash ?? 0.0;
    final diff = actual - expected;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (diff == 0) {
      statusColor = AppColors.success;
      statusLabel = AppStrings.matched;
      statusIcon = Icons.check_circle_rounded;
    } else if (diff < 0) {
      statusColor = AppColors.danger;
      statusLabel = AppStrings.deficit;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AppColors.warning;
      statusLabel = AppStrings.surplus;
      statusIcon = Icons.add_circle_outline_rounded;
    }

    final formattedDate = shift.endTime != null
        ? DateFormat('yyyy-MM-dd hh:mm a').format(shift.endTime!)
        : DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());

    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 48.r),
          SizedBox(height: 12.h),
          AppText.heading(AppStrings.shiftHandoverSummary, fontSize: 20.sp),
          SizedBox(height: 4.h),
          AppText.body(formattedDate, color: AppColors.textSecondary, fontSize: 13.sp),
        ],
      ),
      content: Container(
        width: 420.w,
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: statusColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.body(
                          '${AppStrings.discrepancy}: $statusLabel',
                          color: statusColor,
                          fontSize: 13.sp,
                        ),
                        SizedBox(height: 4.h),
                        AppText.heading(
                          '${diff > 0 ? "+" : (diff < 0 ? "-" : "")}${diff.abs().toStringAsFixed(2)} ${AppStrings.egp}',
                          color: statusColor,
                          fontSize: 22.sp,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(text: statusLabel, color: statusColor),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            _buildDetailRow(AppStrings.countedCash, '${actual.toStringAsFixed(2)} ${AppStrings.egp}'),
            SizedBox(height: 12.h),
            _buildDetailRow(AppStrings.expectedCash, '${expected.toStringAsFixed(2)} ${AppStrings.egp}'),
            if (shift.notes != null && shift.notes!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _buildDetailRow(AppStrings.notes, shift.notes!),
            ],
          ],
        ),
      ),
      actionsPadding: EdgeInsets.all(20.r),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: AppStrings.printHandoverSummary,
                icon: Icons.print_rounded,
                variant: AppButtonVariant.outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.printingTriggered),
                      backgroundColor: AppColors.neonBlue,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AppButton(
                text: AppStrings.done,
                variant: AppButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.body(label, color: AppColors.textSecondary, fontSize: 13.sp),
        AppText.body(value, color: AppColors.textPrimary, fontSize: 13.sp),
      ],
    );
  }
}
