import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';

class PayoutDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> details;

  const PayoutDetailsDialog({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final payout = details['payout'] as Map<String, dynamic>? ?? {};
    final reconciliation = details['reconciliation'] as Map<String, dynamic>? ?? {};

    return AppDialog(
      title: AppStrings.payoutDetailsAndReconciliation,
      actions: [
        AppButton(
          text: AppStrings.close,
          backgroundColor: AppColors.mutedBackground,
          foregroundColor: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      child: SizedBox(
        width: 500.w,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppStrings.status}: ${payout['status'] ?? '-'}',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              Text(
                '${AppStrings.totalAmount}: \$${payout['total_amount'] ?? payout['amount'] ?? '0.00'}',
                style: const TextStyle(color: AppColors.neonGreen),
              ),
              Text(
                '${AppStrings.period}: ${payout['period_start'] ?? '-'} to ${payout['period_end'] ?? '-'}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (payout['transfer_reference'] != null)
                Text(
                  '${AppStrings.transferRef}: ${payout['transfer_reference']} (${payout['transfer_method'] ?? '-'})',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              SizedBox(height: 16.h),
              Text(
                AppStrings.reconciliationSummary,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              SizedBox(height: 8.h),
              Text('${AppStrings.totalPayments} ${reconciliation['payment_count'] ?? 0}', style: const TextStyle(color: AppColors.textSecondary)),
              Text('${AppStrings.completedCount} ${reconciliation['completed_count'] ?? 0}', style: const TextStyle(color: AppColors.textSecondary)),
              Text('${AppStrings.calculatedNet} \$${reconciliation['calculated_net'] ?? 0}', style: const TextStyle(color: AppColors.textSecondary)),
              Text('${AppStrings.difference} \$${reconciliation['difference'] ?? 0}', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
