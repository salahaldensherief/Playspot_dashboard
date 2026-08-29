import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import '../../../domain/entities/shift_entity.dart';

class ShiftSummaryModal extends StatelessWidget {
  final ShiftEntity shift;
  final VoidCallback onFinish;

  const ShiftSummaryModal({super.key, required this.shift, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Center(
        child: Text(
          AppStrings.zReport,
          style: TextStyle(color: AppColors.neonBlue, fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
        ),
      ),
      content: Container(
        width: 400.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRow(AppStrings.cashier, shift.cashierName ?? 'N/A'),
            _buildRow(AppStrings.startTimeLabel, DateFormat('yyyy-MM-dd HH:mm').format(shift.startTime)),
            const Divider(color: AppColors.borderDefault),
            _buildRow(AppStrings.startingCash, '${shift.startingCash.toStringAsFixed(2)} ${AppStrings.egp}'),
            _buildRow(AppStrings.cashRevenue, '${shift.cashRevenue?.toStringAsFixed(2)} ${AppStrings.egp}'),
            _buildRow(AppStrings.digitalRevenue, '${shift.digitalRevenue?.toStringAsFixed(2)} ${AppStrings.egp}', isInfo: true),
            const Divider(color: AppColors.borderDefault),
            _buildRow(AppStrings.expectedCash, '${shift.expectedCash?.toStringAsFixed(2)} ${AppStrings.egp}', isBold: true),
            _buildRow(AppStrings.actualCash, '${shift.actualCash?.toStringAsFixed(2)} ${AppStrings.egp}', isBold: true),
            const Divider(color: AppColors.borderDefault),
            _buildDiscrepancyRow(shift.discrepancy ?? 0),
          ],
        ),
      ),
      actionsPadding: EdgeInsets.only(bottom: 24.h),
      actions: [
        Center(
          child: AppButton(
            text: AppStrings.logoutAfterClose,
            onPressed: onFinish,
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, bool isInfo = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
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
    final color = val == 0 ? AppColors.success : (val < 0 ? AppColors.danger : AppColors.warning);
    final statusText = val == 0 ? 'matched'.tr() : (val < 0 ? 'deficit'.tr() : 'surplus'.tr());

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.discrepancy, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                Text(statusText, style: TextStyle(color: color, fontSize: 12.sp)),
              ],
            ),
            Text(
              '${val.toStringAsFixed(2)} ${AppStrings.egp}',
              style: TextStyle(color: color, fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
