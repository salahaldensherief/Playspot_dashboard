import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';

class PendingPayoutsTab extends StatelessWidget {
  final List<Map<String, dynamic>> pendingOverview;
  final void Function(String loungeId, String loungeName) onCreatePayout;

  const PendingPayoutsTab({
    super.key,
    required this.pendingOverview,
    required this.onCreatePayout,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingOverview.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noPendingPayouts,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return DataTableWidget(
      columns: [
        AppStrings.lounge,
        AppStrings.pendingAmount,
        AppStrings.paymentsCount,
        AppStrings.actions,
      ],
      mobileCardBuilder: (context, index) {
        final p = pendingOverview[index];
        final amount = ((p['pending_amount'] as num?) ?? 0).toStringAsFixed(2);
        return Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      p['lounge_name']?.toString() ?? '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '\$$amount',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppStrings.paymentsCount}: ${p['pending_payments_count'] ?? 0}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                  AppButton(
                    text: AppStrings.createPayout,
                    height: 36.h,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    fontSize: 12.sp,
                    onPressed: () => onCreatePayout(
                      p['lounge_id']?.toString() ?? '',
                      p['lounge_name']?.toString() ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      rows: pendingOverview.map((p) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                p['lounge_name'] ?? '',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataCell(
              Text(
                '\$${((p['pending_amount'] as num?) ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.neonGreen),
              ),
            ),
            DataCell(
              Text(
                (p['pending_payments_count'] ?? 0).toString(),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            DataCell(
              AppButton(
                text: AppStrings.createPayout,
                onPressed: () => onCreatePayout(
                  p['lounge_id']?.toString() ?? '',
                  p['lounge_name']?.toString() ?? '',
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
