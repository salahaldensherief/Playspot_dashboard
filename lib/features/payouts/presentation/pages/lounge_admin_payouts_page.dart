import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoungeAdminPayoutsPage extends StatefulWidget {
  const LoungeAdminPayoutsPage({super.key});

  @override
  State<LoungeAdminPayoutsPage> createState() => _LoungeAdminPayoutsPageState();
}

class _LoungeAdminPayoutsPageState extends State<LoungeAdminPayoutsPage> {
  List<Map<String, dynamic>> _payouts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPayouts();
  }

  Future<void> _fetchPayouts() async {
    final loungeId = context.read<LoginCubit>().state.user?.loungeId;
    if (loungeId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppStrings.actionFailed;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await sl<SupabaseClient>()
          .from('payouts')
          .select()
          .eq('lounge_id', loungeId)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _payouts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('network') || e.toString().contains('Socket')
            ? AppStrings.actionFailed
            : e.toString();
      });
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
        return StatusBadge(text: status.toUpperCase(), color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNeedsReview = _payouts.any((p) => p['status'] == 'needs_review');

    return Padding(
      padding: EdgeInsets.all(24.r),
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
                      style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24.h),
          Expanded(
            child: _isLoading
                ? const TableShimmer(columns: 5)
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48.r, color: AppColors.danger),
                            SizedBox(height: 12.h),
                            Text(
                              _errorMessage!,
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
                    : _payouts.isEmpty
                        ? Center(
                            child: Text(
                              AppStrings.noPayoutHistoryFound,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTableWidget(
                              columns: [
                                AppStrings.period,
                                AppStrings.totalAmount,
                                AppStrings.paymentsCount,
                                AppStrings.status,
                                AppStrings.transferMethod,
                                AppStrings.transferReference,
                                AppStrings.date,
                                AppStrings.paidAt,
                                AppStrings.notes
                              ],
                              rows: _payouts
                                  .map((p) => DataRow(
                                        cells: [
                                          DataCell(Text('${p['period_start']} to ${p['period_end']}',
                                              style: const TextStyle(color: AppColors.textSecondary))),
                                          DataCell(
                                            Text(
                                              '\$${(((p['total_amount'] as num?) ?? (p['amount'] as num?) ?? 0)).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: AppColors.neonGreen,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text((p['payment_count'] ?? '-').toString(),
                                              style: const TextStyle(color: AppColors.textSecondary))),
                                          DataCell(_buildStatusBadge(p['status'] ?? 'pending')),
                                          DataCell(Text(p['transfer_method'] ?? '-',
                                              style: const TextStyle(color: AppColors.textSecondary))),
                                          DataCell(Text(p['transfer_reference'] ?? '-',
                                              style: const TextStyle(color: AppColors.textSecondary))),
                                          DataCell(Text(
                                              p['created_at'] != null
                                                  ? DateFormat('yyyy-MM-dd')
                                                      .format(DateTime.parse(p['created_at']))
                                                  : '-',
                                              style: const TextStyle(color: AppColors.textSecondary))),
                                          DataCell(Text(
                                              p['paid_at'] != null
                                                  ? DateFormat('yyyy-MM-dd HH:mm')
                                                      .format(DateTime.parse(p['paid_at']))
                                                  : '-',
                                              style: const TextStyle(color: AppColors.textSecondary))),
                                          DataCell(
                                              Text(p['notes'] ?? '-', style: const TextStyle(color: AppColors.textMuted))),
                                        ],
                                      ))
                                  .toList(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
