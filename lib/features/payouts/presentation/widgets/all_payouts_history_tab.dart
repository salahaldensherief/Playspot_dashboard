import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
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
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

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
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    if (payouts.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noPayoutHistoryFound,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          DataTableWidget(
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
            mobileCardBuilder: (context, index) =>
                _buildMobilePayoutCard(context, payouts[index]),
            rows: payouts.map((p) {
              final status = p['status']?.toString() ?? 'pending';
              final payoutId = p['id']?.toString() ?? '';
              final createdAt = p['created_at'] != null
                  ? DateFormat(
                      'yyyy-MM-dd',
                    ).format(DateTime.parse(p['created_at']))
                  : '-';
              final paidAt = p['paid_at'] != null
                  ? DateFormat(
                      'yyyy-MM-dd hh:mm a',
                    ).format(DateTime.parse(p['paid_at']))
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
                  DataCell(
                    Text(
                      p['period_start'] ?? '',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      p['period_end'] ?? '',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      '\$${((p['total_amount'] as num?) ?? (p['amount'] as num?) ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.neonGreen),
                    ),
                  ),
                  DataCell(
                    Text(
                      (p['payment_count'] ?? '-').toString(),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(PayoutStatusBadge(status: status)),
                  DataCell(
                    Text(
                      createdAt,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      paidAt,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      p['transfer_reference'] ?? '-',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      p['transfer_method'] ?? '-',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(Wrap(spacing: 8.w, children: actionButtons)),
                ],
              );
            }).toList(),
          ),
          if (hasMore && onLoadMore != null) ...[
            SizedBox(height: 12.h),
            AppButton(
              text: AppStrings.loadMore,
              variant: AppButtonVariant.outlined,
              isLoading: isLoadingMore,
              onPressed: isLoadingMore ? null : onLoadMore,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobilePayoutCard(BuildContext context, Map<String, dynamic> p) {
    final status = p['status']?.toString() ?? 'pending';
    final payoutId = p['id']?.toString() ?? '';
    final createdAt = p['created_at'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(p['created_at']))
        : '-';
    final paidAt = p['paid_at'] != null
        ? DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(p['paid_at']))
        : '-';
    final amount = ((p['total_amount'] as num?) ?? (p['amount'] as num?) ?? 0)
        .toStringAsFixed(2);
    final loungeName = p['lounges']?['name']?.toString() ?? '-';
    final actionButtons = _buildActions(status, payoutId);

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
                  loungeName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PayoutStatusBadge(status: status),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.periodStart}: ${p['period_start'] ?? '-'}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              Text(
                '${AppStrings.periodEnd}: ${p['period_end'] ?? '-'}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$$amount',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              Text(
                '${AppStrings.count}: ${p['payment_count'] ?? '-'}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          if (p['transfer_reference'] != null ||
              p['transfer_method'] != null) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (p['transfer_method'] != null)
                  Text(
                    '${AppStrings.method}: ${p['transfer_method']}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.sp,
                    ),
                  ),
                if (p['transfer_reference'] != null)
                  Text(
                    '${AppStrings.transferRef}: ${p['transfer_reference']}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.sp,
                    ),
                  ),
              ],
            ),
          ],
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.createdAt}: $createdAt',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
              ),
              if (paidAt != '-')
                Text(
                  '${AppStrings.paidAt}: $paidAt',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                ),
            ],
          ),
          if (actionButtons.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(spacing: 8.w, runSpacing: 8.h, children: actionButtons),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActions(String status, String payoutId) {
    final List<Widget> actionButtons = [];

    if (status == 'pending') {
      actionButtons.addAll([
        AppButton(
          text: AppStrings.approve,
          variant: AppButtonVariant.text,
          foregroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          fontSize: 12.sp,
          onPressed: () => onApprove(payoutId),
        ),
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.text,
          foregroundColor: AppColors.danger,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          fontSize: 12.sp,
          onPressed: () => onCancel(payoutId),
        ),
      ]);
    } else if (status == 'approved') {
      actionButtons.addAll([
        AppButton(
          text: AppStrings.process,
          variant: AppButtonVariant.text,
          foregroundColor: Colors.purpleAccent,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          fontSize: 12.sp,
          onPressed: () => onProcess(payoutId),
        ),
        AppButton(
          text: AppStrings.pay,
          variant: AppButtonVariant.text,
          foregroundColor: AppColors.neonGreen,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          fontSize: 12.sp,
          onPressed: () => onPay(payoutId),
        ),
        AppButton(
          text: AppStrings.fail,
          variant: AppButtonVariant.text,
          foregroundColor: Colors.orangeAccent,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          fontSize: 12.sp,
          onPressed: () => onFail(payoutId),
        ),
      ]);
    } else if (status == 'processing') {
      actionButtons.addAll([
        AppButton(
          text: AppStrings.pay,
          variant: AppButtonVariant.text,
          foregroundColor: AppColors.neonGreen,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          fontSize: 12.sp,
          onPressed: () => onPay(payoutId),
        ),
        AppButton(
          text: AppStrings.fail,
          variant: AppButtonVariant.text,
          foregroundColor: Colors.orangeAccent,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          fontSize: 12.sp,
          onPressed: () => onFail(payoutId),
        ),
      ]);
    } else if (status == 'needs_review') {
      actionButtons.addAll([
        AppButton(
          text: AppStrings.resolve,
          variant: AppButtonVariant.text,
          foregroundColor: Colors.amberAccent,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          fontSize: 12.sp,
          onPressed: () => onResolve(payoutId),
        ),
      ]);
    }

    actionButtons.add(
      AppButton(
        text: AppStrings.details,
        variant: AppButtonVariant.text,
        foregroundColor: AppColors.neonCyan,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        fontSize: 12.sp,
        onPressed: () => onViewDetails(payoutId),
      ),
    );

    return actionButtons;
  }
}
