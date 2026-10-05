import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/layouts/dashboard_layout.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../../domain/entities/payout_entity.dart';
import '../cubit/payout_cubit.dart';
import '../cubit/payout_state.dart';

class LoungeAdminPayoutsPage extends StatefulWidget {
  const LoungeAdminPayoutsPage({super.key});

  @override
  State<LoungeAdminPayoutsPage> createState() => _LoungeAdminPayoutsPageState();
}

class _LoungeAdminPayoutsPageState extends State<LoungeAdminPayoutsPage> {
  @override
  void initState() {
    super.initState();
    _fetchPayouts();
  }

  void _fetchPayouts() {
    final loungeId = context.read<LoginCubit>().state.user?.loungeId;
    if (loungeId != null) {
      context.read<PayoutCubit>().loadLoungePayouts(loungeId);
    }
  }

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'pending':
        return StatusBadge.warning('PENDING');
      case 'approved':
        return StatusBadge.info('APPROVED');
      case 'processing':
        return StatusBadge(text: 'PROCESSING', color: Colors.purpleAccent);
      case 'paid':
        return StatusBadge.success('PAID');
      case 'failed':
        return StatusBadge.danger('FAILED');
      case 'cancelled':
        return StatusBadge(text: 'CANCELLED', color: Colors.grey);
      case 'reversed':
        return StatusBadge(text: 'REVERSED', color: Colors.deepOrange);
      case 'needs_review':
        return StatusBadge(text: 'NEEDS REVIEW', color: Colors.redAccent);
      default:
        return StatusBadge(
          text: status.toUpperCase(),
          color: AppColors.textPrimary,
        );
    }
  }

  Widget _buildMobilePayoutCard(PayoutEntity p) {
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
              Text(
                '\$${p.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusBadge(p.status),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${p.periodStart} ${AppStrings.to} ${p.periodEnd}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              Text(
                DateFormat('yyyy-MM-dd').format(p.createdAt),
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
              ),
            ],
          ),
          if (p.transferMethod != null || p.transferReference != null) ...[
            SizedBox(height: 8.h),
            Text(
              '${p.transferMethod ?? ''} ${p.transferReference != null ? '(#${p.transferReference})' : ''}'
                  .trim(),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
            ),
          ],
          if (p.notes != null && (p.notes?.isNotEmpty ?? false)) ...[
            SizedBox(height: 6.h),
            Text(
              p.notes ?? '',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PayoutCubit, PayoutState>(
      listener: (context, state) {
        if (state.status == PayoutCubitStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? ''),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        final payouts = state.loungePayouts;
        final hasNeedsReview = payouts.any((p) => p.status == 'needs_review');
        final isLoading =
            state.status == PayoutCubitStatus.loading && payouts.isEmpty;
        final loungeId = context.read<LoginCubit>().state.user?.loungeId;

        return DashboardLayout(
          title: AppStrings.myPayoutsHistory,
          activeRoute: 'Payouts',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.myPayoutsHistory,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              if (hasNeedsReview) ...[
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.payoutReconciliationWarning,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 24.h),
              if (isLoading)
                const TableShimmer(columns: 5)
              else if (state.status == PayoutCubitStatus.failure &&
                  payouts.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48.r,
                        color: AppColors.danger,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        state.errorMessage ?? AppStrings.actionFailed,
                        style: const TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      AppButton(
                        text: AppStrings.retry,
                        icon: Icons.refresh_rounded,
                        onPressed: _fetchPayouts,
                      ),
                    ],
                  ),
                )
              else if (payouts.isEmpty)
                Center(
                  child: Text(
                    AppStrings.noPayoutHistoryFound,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                Column(
                  children: [
                    DataTableWidget(
                      mobileCardBuilder: (ctx, index) {
                        return _buildMobilePayoutCard(payouts[index]);
                      },
                      columns: [
                        AppStrings.period,
                        AppStrings.totalAmount,
                        AppStrings.paymentsCount,
                        AppStrings.status,
                        AppStrings.transferMethod,
                        AppStrings.transferReference,
                        AppStrings.date,
                        AppStrings.paidAt,
                        AppStrings.notes,
                      ],
                      rows: payouts
                          .map(
                            (p) => DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '${p.periodStart} ${AppStrings.to} ${p.periodEnd}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '\$${p.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: AppColors.neonGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    (p.paymentCount ?? '-').toString(),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                DataCell(_buildStatusBadge(p.status)),
                                DataCell(
                                  Text(
                                    p.transferMethod ?? '-',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    p.transferReference ?? '-',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(p.createdAt),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    p.paidAt != null
                                        ? DateFormat(
                                            'yyyy-MM-dd hh:mm a',
                                          ).format(p.paidAt!)
                                        : '-',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    p.notes ?? '-',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                    if (state.loungePayoutsHasMore) ...[
                      SizedBox(height: 12.h),
                      AppButton(
                        text: AppStrings.loadMore,
                        variant: AppButtonVariant.outlined,
                        isLoading: state.loungePayoutsLoadingMore,
                        onPressed:
                            state.loungePayoutsLoadingMore || loungeId == null
                            ? null
                            : () => context
                                  .read<PayoutCubit>()
                                  .loadMoreLoungePayouts(loungeId),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
