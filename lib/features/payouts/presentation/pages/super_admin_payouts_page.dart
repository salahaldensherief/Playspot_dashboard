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
import 'package:supabase_flutter/supabase_flutter.dart';

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
    try {
      final supabase = sl<SupabaseClient>();
      final overviewRes = await supabase.rpc('get_pending_payouts_overview');
      final payoutsRes = await supabase
          .from('payouts')
          .select('*, lounges(name)')
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _pendingOverview = List<Map<String, dynamic>>.from(overviewRes);
        _allPayouts = List<Map<String, dynamic>>.from(payoutsRes);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.error}: $e')));
    }
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
                          try {
                            final result = await sl<SupabaseClient>().rpc('create_payout', params: {
                              'p_lounge_id': loungeId,
                              'p_period_start': startController.text,
                              'p_period_end': endController.text,
                            });
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (result['success'] == true) {
                              messenger.showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${AppStrings.payoutCreatedSuccess} \$${result['amount']} (${result['payment_count']} ${AppStrings.paymentsCount})')),
                              );
                              _fetchData();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = e.toString();
                            });
                          }
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
                        try {
                          await sl<SupabaseClient>().rpc('complete_payout', params: {
                            'p_payout_id': payoutId,
                            'p_transfer_method': transferMethod,
                            'p_transfer_reference': refController.text.trim(),
                            'p_receipt_url':
                                receiptController.text.trim().isEmpty ? null : receiptController.text.trim(),
                            'p_notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          });
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          messenger.showSnackBar(
                            SnackBar(content: Text(AppStrings.payoutMarkedPaidSuccess)),
                          );
                          _fetchData();
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = e.toString();
                          });
                        }
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
                        try {
                          await sl<SupabaseClient>().rpc(rpcName, params: {
                            'p_payout_id': payoutId,
                            'p_reason': reasonController.text.trim(),
                          });
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          messenger.showSnackBar(SnackBar(content: Text(AppStrings.actionExecutedSuccess)));
                          _fetchData();
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = e.toString();
                          });
                        }
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
                        try {
                          await sl<SupabaseClient>().rpc('resolve_payout_review', params: {
                            'p_payout_id': payoutId,
                            'p_resolution': resolution,
                            'p_reason': reasonController.text.trim(),
                          });
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          messenger.showSnackBar(
                              SnackBar(content: Text(AppStrings.payoutReviewResolvedSuccess)));
                          _fetchData();
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = e.toString();
                          });
                        }
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
    try {
      final details = await sl<SupabaseClient>().rpc('get_payout_details', params: {
        'p_payout_id': payoutId,
      });

      if (!mounted) return;

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.error}: $e')));
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
                                          try {
                                            await sl<SupabaseClient>()
                                                .rpc('approve_payout', params: {'p_payout_id': p['id']});
                                            _fetchData();
                                          } catch (e) {
                                            if (!mounted) return;
                                            messenger.showSnackBar(SnackBar(content: Text('${AppStrings.error}: $e')));
                                          }
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
                                          try {
                                            await sl<SupabaseClient>().rpc('start_payout_processing',
                                                params: {'p_payout_id': p['id']});
                                            _fetchData();
                                          } catch (e) {
                                            if (!mounted) return;
                                            messenger.showSnackBar(SnackBar(content: Text('${AppStrings.error}: $e')));
                                          }
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
