import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../domain/repositories/payout_repository.dart';


class SuperAdminPayoutsPage extends StatefulWidget {
  const SuperAdminPayoutsPage({super.key});

  @override
  State<SuperAdminPayoutsPage> createState() => _SuperAdminPayoutsPageState();
}

class _SuperAdminPayoutsPageState extends State<SuperAdminPayoutsPage> with SingleTickerProviderStateMixin {
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


  Future<void> _createPayoutModal(String loungeId, String loungeName) async {
    final startController = TextEditingController(text: '2026-01-01');
    final endController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppDialog(
              title: AppStrings.createPayoutFor(loungeName),
              actions: [
                AppButton(
                  text: AppStrings.cancel,
                  backgroundColor: AppColors.mutedBackground,
                  foregroundColor: AppColors.textPrimary,
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                ),
                AppButton(
                  text: AppStrings.create,
                  isLoading: isSubmitting,
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setDialogState(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });
                          final resultEither = await sl<PayoutRepository>().createPayout(
                            loungeId: loungeId,
                            periodStart: startController.text,
                            periodEnd: endController.text,
                          );
                          resultEither.fold(
                            (failure) {
                              setDialogState(() {
                                isSubmitting = false;
                                errorMessage = failure.message;
                              });
                            },
                            (result) {
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              if (result['success'] == true) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${AppStrings.payoutCreatedSuccess} \$${result['amount']} (${result['payment_count']} ${AppStrings.paymentsCount})',
                                    ),
                                  ),
                                );
                              }
                              _fetchData();
                            },
                          );
                        },
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(label: AppStrings.periodStart, controller: startController),
                  SizedBox(height: 16.h),
                  AppTextField(label: AppStrings.periodEnd, controller: endController),
                  if (errorMessage != null) ...[
                    SizedBox(height: 12.h),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completePayoutModal(String payoutId) async {
    String transferMethod = 'instapay';
    final refController = TextEditingController();
    final receiptController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) => AppDialog(
            title: AppStrings.completePayoutPayment,
            actions: [
              AppButton(
                text: AppStrings.cancel,
                backgroundColor: AppColors.mutedBackground,
                foregroundColor: AppColors.textPrimary,
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              ),
              AppButton(
                text: AppStrings.completePayment,
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (refController.text.trim().isEmpty) {
                          setDialogState(() => errorMessage = AppStrings.transferRefRequiredError);
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        final resultEither = await sl<PayoutRepository>().completePayout(
                          payoutId: payoutId,
                          transferMethod: transferMethod,
                          transferReference: refController.text.trim(),
                          receiptUrl:
                              receiptController.text.trim().isEmpty ? null : receiptController.text.trim(),
                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        );
                        resultEither.fold(
                          (failure) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = failure.message;
                            });
                          },
                          (_) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            messenger.showSnackBar(
                              SnackBar(content: Text(AppStrings.payoutMarkedPaidSuccess)),
                            );
                            _fetchData();
                          },
                        );
                      },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.transferMethod, style: const TextStyle(color: AppColors.textSecondary)),
                DropdownButton<String>(
                  value: transferMethod,
                  dropdownColor: AppColors.cardBackground,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: ['bank_transfer', 'instapay', 'vodafone_cash', 'cash', 'other']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.toUpperCase())))
                      .toList(),
                  onChanged: isSubmitting
                      ? null
                      : (val) {
                          if (val != null) setDialogState(() => transferMethod = val);
                        },
                ),
                SizedBox(height: 16.h),
                AppTextField(label: AppStrings.transferRefRequired, controller: refController),
                SizedBox(height: 16.h),
                AppTextField(label: AppStrings.receiptUrlOptional, controller: receiptController),
                SizedBox(height: 16.h),
                AppTextField(label: AppStrings.notesOptional, controller: notesController),
                if (errorMessage != null) ...[
                  SizedBox(height: 12.h),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _actionWithReasonModal(String title, String rpcName, String payoutId) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) => AppDialog(
            title: title,
            actions: [
              AppButton(
                text: AppStrings.cancel,
                backgroundColor: AppColors.mutedBackground,
                foregroundColor: AppColors.textPrimary,
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              ),
              AppButton(
                text: AppStrings.confirm,
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        final repo = sl<PayoutRepository>();
                        final reason = reasonController.text.trim();
                        final result = rpcName == 'approve_payout'
                            ? await repo.approvePayout(payoutId: payoutId, notes: reason)
                            : rpcName == 'fail_payout'
                                ? await repo.failPayout(payoutId: payoutId, reason: reason)
                                : await repo.cancelPayout(payoutId: payoutId, reason: reason);
                        result.fold(
                          (failure) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = failure.message;
                            });
                          },
                          (_) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            messenger.showSnackBar(SnackBar(content: Text(AppStrings.actionExecutedSuccess)));
                            _fetchData();
                          },
                        );
                      },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(label: AppStrings.reasonNotes, controller: reasonController),
                if (errorMessage != null) ...[
                  SizedBox(height: 12.h),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _resolveReviewModal(String payoutId) async {
    String resolution = 'approve';
    final reasonController = TextEditingController(text: 'Verified manually with finance records');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) => AppDialog(
            title: AppStrings.resolvePayoutReview,
            actions: [
              AppButton(
                text: AppStrings.cancel,
                backgroundColor: AppColors.mutedBackground,
                foregroundColor: AppColors.textPrimary,
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              ),
              AppButton(
                text: AppStrings.resolve,
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        final result = await sl<PayoutRepository>().resolvePayoutReview(
                          payoutId: payoutId,
                          resolution: resolution,
                          reason: reasonController.text.trim(),
                        );
                        result.fold(
                          (failure) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = failure.message;
                            });
                          },
                          (_) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            messenger.showSnackBar(
                                SnackBar(content: Text(AppStrings.payoutReviewResolvedSuccess)));
                            _fetchData();
                          },
                        );
                      },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.reconciliationWarning,
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                SizedBox(height: 16.h),
                Text(AppStrings.resolutionAction, style: const TextStyle(color: AppColors.textSecondary)),
                DropdownButton<String>(
                  value: resolution,
                  dropdownColor: AppColors.cardBackground,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: [
                    DropdownMenuItem(value: 'approve', child: Text(AppStrings.approveAndMoveToPending)),
                    DropdownMenuItem(value: 'cancel', child: Text(AppStrings.cancelPayout)),
                  ],
                  onChanged: isSubmitting
                      ? null
                      : (val) {
                          if (val != null) setDialogState(() => resolution = val);
                        },
                ),
                SizedBox(height: 16.h),
                AppTextField(label: AppStrings.reasonNotes, controller: reasonController),
                if (errorMessage != null) ...[
                  SizedBox(height: 12.h),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _viewDetailsModal(String payoutId) async {
    final detailsRes = await sl<PayoutRepository>().getPayoutDetails(payoutId: payoutId);
    if (!mounted) return;

    detailsRes.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (details) {
        showDialog(
          context: context,
        builder: (context) => AppDialog(
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
                  Text('${AppStrings.status}: ${details['payout']['status']}',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  Text('${AppStrings.totalAmount}: \$${details['payout']['total_amount'] ?? details['payout']['amount']}',
                      style: const TextStyle(color: AppColors.neonGreen)),
                  Text('${AppStrings.period}: ${details['payout']['period_start']} to ${details['payout']['period_end']}'),
                  if (details['payout']['transfer_reference'] != null)
                    Text(
                        '${AppStrings.transferRef}: ${details['payout']['transfer_reference']} (${details['payout']['transfer_method']})'),
                  SizedBox(height: 16.h),
                  Text(AppStrings.reconciliationSummary,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text('${AppStrings.totalPayments} ${details['reconciliation']['payment_count']}'),
                  Text('${AppStrings.completedCount} ${details['reconciliation']['completed_count']}'),
                  Text('${AppStrings.calculatedNet} \$${details['reconciliation']['calculated_net']}'),
                  Text('${AppStrings.difference} \$${details['reconciliation']['difference']}'),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
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
                      // Tab 1: Pending Overview
                      _pendingOverview.isEmpty
                          ? Center(
                              child: Text(AppStrings.noPendingPayouts,
                                  style: const TextStyle(color: AppColors.textSecondary)))
                          : DataTableWidget(
                              columns: [AppStrings.lounge, AppStrings.pendingAmount, AppStrings.paymentsCount, AppStrings.actions],
                              rows: _pendingOverview
                                  .map((p) => DataRow(
                                        cells: [
                                          DataCell(Text(p['lounge_name'] ?? '',
                                              style: const TextStyle(
                                                  color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
                                          DataCell(Text(
                                              '\$${((p['pending_amount'] as num?) ?? 0).toStringAsFixed(2)}',
                                              style: const TextStyle(color: AppColors.neonGreen))),
                                          DataCell(Text((p['pending_payments_count'] ?? 0).toString(),
                                              style: const TextStyle(color: AppColors.textSecondary))),
                                          DataCell(
                                            AppButton(
                                              text: AppStrings.createPayout,
                                              onPressed: () =>
                                                  _createPayoutModal(p['lounge_id'], p['lounge_name']),
                                            ),
                                          ),
                                        ],
                                      ))
                                  .toList(),
                            ),

                      // Tab 2: All Payouts
                      _allPayouts.isEmpty
                          ? Center(
                              child: Text(AppStrings.noPayoutHistoryFound,
                                  style: const TextStyle(color: AppColors.textSecondary)))
                          : SingleChildScrollView(
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
                                  AppStrings.actions
                                ],
                                rows: _allPayouts.map((p) {
                                  final status = p['status'] ?? 'pending';
                                  final createdAt = p['created_at'] != null
                                      ? DateFormat('yyyy-MM-dd').format(DateTime.parse(p['created_at']))
                                      : '-';
                                  final paidAt = p['paid_at'] != null
                                      ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(p['paid_at']))
                                      : '-';

                                  List<Widget> actionButtons = [];

                                  if (status == 'pending') {
                                    actionButtons.addAll([
                                      TextButton(
                                        onPressed: () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          final res = await sl<PayoutRepository>().approvePayout(payoutId: p['id']);
                                          res.fold(
                                            (failure) => messenger.showSnackBar(SnackBar(content: Text(failure.message))),
                                            (_) => _fetchData(),
                                          );
                                        },
                                        child: Text(AppStrings.approve, style: const TextStyle(color: Colors.blueAccent)),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _actionWithReasonModal(AppStrings.cancelPayout, 'cancel_payout', p['id']),
                                        child: Text(AppStrings.cancel, style: const TextStyle(color: Colors.redAccent)),
                                      ),
                                    ]);
                                  } else if (status == 'approved') {
                                    actionButtons.addAll([
                                      TextButton(
                                        onPressed: () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          final res = await sl<PayoutRepository>().startPayoutProcessing(payoutId: p['id']);
                                          res.fold(
                                            (failure) => messenger.showSnackBar(SnackBar(content: Text(failure.message))),
                                            (_) => _fetchData(),
                                          );
                                        },
                                        child: Text(AppStrings.process, style: const TextStyle(color: Colors.purpleAccent)),
                                      ),
                                      TextButton(
                                        onPressed: () => _completePayoutModal(p['id']),
                                        child: Text(AppStrings.pay, style: const TextStyle(color: Colors.greenAccent)),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _actionWithReasonModal('Mark Failed', 'fail_payout', p['id']),
                                        child: Text(AppStrings.fail, style: const TextStyle(color: Colors.orangeAccent)),
                                      ),
                                    ]);
                                  } else if (status == 'processing') {
                                    actionButtons.addAll([
                                      TextButton(
                                        onPressed: () => _completePayoutModal(p['id']),
                                        child: Text(AppStrings.pay, style: const TextStyle(color: Colors.greenAccent)),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _actionWithReasonModal('Mark Failed', 'fail_payout', p['id']),
                                        child: Text(AppStrings.fail, style: const TextStyle(color: Colors.orangeAccent)),
                                      ),
                                    ]);
                                  } else if (status == 'needs_review') {
                                    actionButtons.addAll([
                                      TextButton(
                                        onPressed: () => _resolveReviewModal(p['id']),
                                        child: Text(AppStrings.resolve, style: const TextStyle(color: Colors.amberAccent)),
                                      ),
                                    ]);
                                  }

                                  actionButtons.add(
                                    TextButton(
                                      onPressed: () => _viewDetailsModal(p['id']),
                                      child: Text(AppStrings.details, style: const TextStyle(color: AppColors.neonCyan)),
                                    ),
                                  );

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(p['lounges']?['name'] ?? '-',
                                          style: const TextStyle(
                                              color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
                                      DataCell(Text(p['period_start'] ?? '',
                                          style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(Text(p['period_end'] ?? '',
                                          style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(Text(
                                          '\$${((p['total_amount'] as num?) ?? (p['amount'] as num?) ?? 0).toStringAsFixed(2)}',
                                          style: const TextStyle(color: AppColors.neonGreen))),
                                      DataCell(Text((p['payment_count'] ?? '-').toString(),
                                          style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(_buildStatusBadge(status)),
                                      DataCell(
                                          Text(createdAt, style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(Text(paidAt, style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(Text(p['transfer_reference'] ?? '-',
                                          style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(Text(p['transfer_method'] ?? '-',
                                          style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(Wrap(spacing: 8.w, children: actionButtons)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
