import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'payout_status_badge.dart';

class AllPayoutsHistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> payouts;
  final void Function(String payoutId) onApprove;
  final void Function(String payoutId) onCancel;
  final void Function(String payoutId) onProcess;
  final void Function(String payoutId) onPay;
  final void Function(String payoutId) onFail;
  final void Function(String payoutId) onResolve;
  final void Function(String payoutId) onViewDetails;

  const AllPayoutsHistoryTab({
    super.key,
    required this.payouts,
    required this.onApprove,
    required this.onCancel,
    required this.onProcess,
    required this.onPay,
    required this.onFail,
    required this.onResolve,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (payouts.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noPayoutHistoryFound,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTableWidget(
        columns: [
          AppStrings.lounge,
          AppStrings.periodStart,
          AppStrings.periodEnd,
          AppStrings.totalAmount,
          AppStrings.count,
          AppStrings.status,
          AppStrings.createdAt,
          AppStrings.paidAt,
          AppStrings.transferRef,
          AppStrings.method,
          AppStrings.actions,
        ],
        rows: payouts.map((p) {
          final status = p['status']?.toString() ?? 'pending';
          final payoutId = p['id']?.toString() ?? '';
          final createdAt = p['created_at'] != null
              ? DateFormat('yyyy-MM-dd').format(DateTime.parse(p['created_at']))
              : '-';
          final paidAt = p['paid_at'] != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(p['paid_at']))
              : '-';

          final actionButtons = _buildActions(status, payoutId);

          return DataRow(
            cells: [
              DataCell(
                Text(
                  p['lounges']?['name'] ?? '-',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(Text(p['period_start'] ?? '', style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Text(p['period_end'] ?? '', style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(
                Text(
                  '\$${((p['total_amount'] as num?) ?? (p['amount'] as num?) ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.neonGreen),
                ),
              ),
              DataCell(Text((p['payment_count'] ?? '-').toString(), style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(PayoutStatusBadge(status: status)),
              DataCell(Text(createdAt, style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Text(paidAt, style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Text(p['transfer_reference'] ?? '-', style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Text(p['transfer_method'] ?? '-', style: const TextStyle(color: AppColors.textSecondary))),
              DataCell(Wrap(spacing: 8.w, children: actionButtons)),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildActions(String status, String payoutId) {
    final List<Widget> actionButtons = [];

    if (status == 'pending') {
      actionButtons.addAll([
        TextButton(
          onPressed: () => onApprove(payoutId),
          child: Text(AppStrings.approve, style: const TextStyle(color: Colors.blueAccent)),
        ),
        TextButton(
          onPressed: () => onCancel(payoutId),
          child: Text(AppStrings.cancel, style: const TextStyle(color: Colors.redAccent)),
        ),
      ]);
    } else if (status == 'approved') {
      actionButtons.addAll([
        TextButton(
          onPressed: () => onProcess(payoutId),
          child: Text(AppStrings.process, style: const TextStyle(color: Colors.purpleAccent)),
        ),
        TextButton(
          onPressed: () => onPay(payoutId),
          child: Text(AppStrings.pay, style: const TextStyle(color: Colors.greenAccent)),
        ),
        TextButton(
          onPressed: () => onFail(payoutId),
          child: Text(AppStrings.fail, style: const TextStyle(color: Colors.orangeAccent)),
        ),
      ]);
    } else if (status == 'processing') {
      actionButtons.addAll([
        TextButton(
          onPressed: () => onPay(payoutId),
          child: Text(AppStrings.pay, style: const TextStyle(color: Colors.greenAccent)),
        ),
        TextButton(
          onPressed: () => onFail(payoutId),
          child: Text(AppStrings.fail, style: const TextStyle(color: Colors.orangeAccent)),
        ),
      ]);
    } else if (status == 'needs_review') {
      actionButtons.addAll([
        TextButton(
          onPressed: () => onResolve(payoutId),
          child: Text(AppStrings.resolve, style: const TextStyle(color: Colors.amberAccent)),
        ),
      ]);
    }

    actionButtons.add(
      TextButton(
        onPressed: () => onViewDetails(payoutId),
        child: Text(AppStrings.details, style: const TextStyle(color: AppColors.neonCyan)),
      ),
    );

    return actionButtons;
  }
}
