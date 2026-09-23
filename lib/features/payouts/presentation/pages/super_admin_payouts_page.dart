import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../domain/repositories/payout_repository.dart';
import '../widgets/all_payouts_history_tab.dart';
import '../widgets/complete_payout_dialog.dart';
import '../widgets/create_payout_dialog.dart';
import '../widgets/payout_details_dialog.dart';
import '../widgets/payout_reason_dialog.dart';
import '../widgets/pending_payouts_tab.dart';
import '../widgets/resolve_payout_review_dialog.dart';

class SuperAdminPayoutsPage extends StatefulWidget {
  const SuperAdminPayoutsPage({super.key});

  @override
  State<SuperAdminPayoutsPage> createState() => _SuperAdminPayoutsPageState();
}

class _SuperAdminPayoutsPageState extends State<SuperAdminPayoutsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingOverview = [];
  List<Map<String, dynamic>> _allPayouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final repo = sl<PayoutRepository>();
    final overviewRes = await repo.getPendingPayoutsOverview();
    final payoutsRes = await repo.getAllPayouts();

    if (!mounted) return;

    overviewRes.fold(
      (failure) {
        AppLogger.error('Failed to load pending payouts overview: ${failure.message}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
        setState(() => _isLoading = false);
      },
      (overview) {
        payoutsRes.fold(
          (failure) {
            AppLogger.error('Failed to load all payouts: ${failure.message}');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
            setState(() => _isLoading = false);
          },
          (payouts) {
            setState(() {
              _pendingOverview = overview
                  .map((o) => {
                        'lounge_id': o.loungeId,
                        'lounge_name': o.loungeName,
                        'pending_amount': o.pendingAmount,
                        'pending_payments_count': o.pendingPaymentsCount,
                      })
                  .toList();
              _allPayouts = payouts
                  .map((p) => {
                        'id': p.id,
                        'lounge_id': p.loungeId,
                        'lounges': {'name': p.loungeName ?? '-'},
                        'amount': p.amount,
                        'total_amount': p.amount,
                        'period_start': p.periodStart,
                        'period_end': p.periodEnd,
                        'status': p.status,
                        'notes': p.notes,
                        'created_at': p.createdAt.toIso8601String(),
                        'paid_at': p.paidAt?.toIso8601String(),
                        'transfer_reference': p.transferReference,
                        'transfer_method': p.transferMethod,
                        'payment_count': p.paymentCount,
                      })
                  .toList();
              _isLoading = false;
            });
          },
        );
      },
    );
  }

  void _showCreatePayout(String loungeId, String loungeName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreatePayoutDialog(
        loungeId: loungeId,
        loungeName: loungeName,
        onSuccess: _fetchData,
      ),
    );
  }

  void _showCompletePayout(String payoutId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletePayoutDialog(
        payoutId: payoutId,
        onSuccess: _fetchData,
      ),
    );
  }

  void _showActionWithReason(String title, String rpcName, String payoutId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PayoutReasonDialog(
        title: title,
        rpcName: rpcName,
        payoutId: payoutId,
        onSuccess: _fetchData,
      ),
    );
  }

  void _showResolveReview(String payoutId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ResolvePayoutReviewDialog(
        payoutId: payoutId,
        onSuccess: _fetchData,
      ),
    );
  }

  Future<void> _viewDetails(String payoutId) async {
    final detailsRes = await sl<PayoutRepository>().getPayoutDetails(payoutId: payoutId);
    if (!mounted) return;

    detailsRes.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (details) => showDialog(
        context: context,
        builder: (_) => PayoutDetailsDialog(details: details),
      ),
    );
  }

  Future<void> _approvePayout(String payoutId) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await sl<PayoutRepository>().approvePayout(payoutId: payoutId);
    res.fold(
      (failure) => messenger.showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => _fetchData(),
    );
  }

  Future<void> _processPayout(String payoutId) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await sl<PayoutRepository>().startPayoutProcessing(payoutId: payoutId);
    res.fold(
      (failure) => messenger.showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => _fetchData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.loungePayouts,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.neonCyan),
                onPressed: _fetchData,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.neonCyan,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: AppStrings.pendingOverview),
              Tab(text: AppStrings.allPayoutsHistory),
            ],
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: _isLoading
                ? const TableShimmer(columns: 5)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      PendingPayoutsTab(
                        pendingOverview: _pendingOverview,
                        onCreatePayout: _showCreatePayout,
                      ),
                      AllPayoutsHistoryTab(
                        payouts: _allPayouts,
                        onApprove: _approvePayout,
                        onCancel: (id) => _showActionWithReason(AppStrings.cancelPayout, 'cancel_payout', id),
                        onProcess: _processPayout,
                        onPay: _showCompletePayout,
                        onFail: (id) => _showActionWithReason('Mark Failed', 'fail_payout', id),
                        onResolve: _showResolveReview,
                        onViewDetails: _viewDetails,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
