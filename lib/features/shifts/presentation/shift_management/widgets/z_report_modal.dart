import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import '../../../domain/entities/shift_entity.dart';

class ZReportModal extends StatelessWidget {
  final ShiftEntity report;

  const ZReportModal({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final discrepancy = (report.actualCash ?? 0) - (report.expectedCash ?? 0);
    final isHealthy = discrepancy >= 0;

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 500.w,
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.zReport,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: AppColors.divider, height: 32.h),
            _buildInfoRow('Shift ID', '#${report.id.substring(0, 8)}'),
            _buildInfoRow(AppStrings.cashier, report.cashierName ?? 'N/A'),
            _buildInfoRow(AppStrings.startTimeLabel, DateFormat('yyyy-MM-dd hh:mm a').format(report.startTime)),
            _buildInfoRow('End Time', DateFormat('yyyy-MM-dd hh:mm a').format(report.endTime ?? DateTime.now())),
            SizedBox(height: 24.h),
            _buildFinancialSummary(discrepancy, isHealthy),
            SizedBox(height: 32.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: AppStrings.printReport,
                    icon: Icons.print,
                    variant: AppButtonVariant.outlined,
                    onPressed: () {
                      // TODO: Implement PDF Print
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppButton(
                    text: AppStrings.logoutAfterClose,
                    icon: Icons.logout,
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Call Logout logic if needed
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(double discrepancy, bool isHealthy) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          _buildMoneyRow(AppStrings.startingCash, report.startingCash),
          _buildMoneyRow(AppStrings.cashRevenue, report.cashRevenue ?? 0),
          _buildMoneyRow(AppStrings.digitalRevenue, report.digitalRevenue ?? 0),
          const Divider(color: AppColors.divider),
          _buildMoneyRow(AppStrings.totalRevenue, report.totalRevenue ?? 0, isBold: true),
          _buildMoneyRow(AppStrings.expectedCash, report.expectedCash ?? 0, isBold: true),
          _buildMoneyRow(AppStrings.actualCash, report.actualCash ?? 0, isBold: true, color: AppColors.neonBlue),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: (isHealthy ? AppColors.success : AppColors.danger).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.discrepancy, style: TextStyle(color: isHealthy ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold)),
                Text(
                  '${discrepancy.toStringAsFixed(2)} EGP',
                  style: TextStyle(color: isHealthy ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold, fontSize: 18.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp, fontWeight: isBold ? FontWeight.bold : null)),
          Text(
            '${amount.toStringAsFixed(2)} EGP',
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
