import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import '../../../domain/entities/shift_entity.dart';

class ShiftSummaryModal extends StatelessWidget {
  final ShiftEntity shift;
  final VoidCallback onFinish;

  const ShiftSummaryModal({
    super.key,
    required this.shift,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppStrings.zReport,
      icon: Icons.receipt_long_outlined,
      maxWidth: 440.w,
      actions: [
        AppButton(text: AppStrings.logoutAfterClose, onPressed: onFinish),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(AppStrings.cashier, shift.cashierName ?? 'N/A'),
          _buildRow(
            AppStrings.startTimeLabel,
            DateFormat('yyyy-MM-dd hh:mm a').format(shift.startTime),
          ),
          const Divider(color: AppColors.borderDefault),
          if (shift.financialsVisible) ...[
            _buildRow(
              AppStrings.startingCash,
              '${shift.startingCash.toStringAsFixed(2)} ${AppStrings.egp}',
            ),
            _buildRow(
              AppStrings.cashRevenue,
              '${shift.cashRevenue?.toStringAsFixed(2)} ${AppStrings.egp}',
            ),
            _buildRow(
              AppStrings.digitalRevenue,
              '${shift.digitalRevenue?.toStringAsFixed(2)} ${AppStrings.egp}',
              isInfo: true,
            ),
            const Divider(color: AppColors.borderDefault),
            _buildRow(
              AppStrings.expectedCash,
              '${shift.expectedCash?.toStringAsFixed(2)} ${AppStrings.egp}',
              isBold: true,
            ),
          ] else
            Text(AppStrings.shiftFinancialsWithheld),
          _buildRow(
            AppStrings.actualCash,
            '${shift.actualCash?.toStringAsFixed(2)} ${AppStrings.egp}',
            isBold: true,
          ),
          const Divider(color: AppColors.borderDefault),
          if (shift.financialsVisible && shift.discrepancy != null)
            _buildDiscrepancyRow(shift.discrepancy!),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    bool isInfo = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
          ),
          Text(
            value,
            style: TextStyle(
              color: isInfo ? AppColors.neonBlue : AppColors.textPrimary,
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscrepancyRow(double val) {
    final color = val == 0
        ? AppColors.success
        : (val < 0 ? AppColors.danger : AppColors.warning);
    final statusText = val == 0
        ? AppStrings.matched
        : (val < 0 ? AppStrings.deficit : AppStrings.surplus);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.discrepancy,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                Text(
                  statusText,
                  style: TextStyle(color: color, fontSize: 12.sp),
                ),
              ],
            ),
            Text(
              '${val.toStringAsFixed(2)} ${AppStrings.egp}',
              style: TextStyle(
                color: color,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
