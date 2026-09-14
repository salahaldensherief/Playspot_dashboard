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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _createPayoutModal(String loungeId, String loungeName) async {
    final startController = TextEditingController(text: '2026-01-01');
    final endController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);

    await showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: 'Create Payout for $loungeName',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Period Start (YYYY-MM-DD)', controller: startController),
            SizedBox(height: 16.h),
            AppTextField(label: 'Period End (YYYY-MM-DD)', controller: endController),
          ],
        ),
        actions: [
          AppButton(
            text: 'Cancel',
            backgroundColor: AppColors.mutedBackground,
            foregroundColor: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            text: 'Create',
            onPressed: () async {
              Navigator.pop(context);
              try {
                final result = await sl<SupabaseClient>().rpc('create_payout', params: {
                  'p_lounge_id': loungeId,
                  'p_period_start': startController.text,
                  'p_period_end': endController.text,
                });
                if (!mounted) return;
                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payout created successfully! Amount: \$${result['amount']} (${result['payment_count']} payments)')),
                  );
                  _fetchData();
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _completePayoutModal(String payoutId) async {
    String transferMethod = 'instapay';
    final refController = TextEditingController();
    final receiptController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: 'Complete Payout (Payment)',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transfer Method', style: TextStyle(color: AppColors.textSecondary)),
              DropdownButton<String>(
                value: transferMethod,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: AppColors.textPrimary),
                items: ['bank_transfer', 'instapay', 'vodafone_cash', 'cash', 'other']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.toUpperCase())))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => transferMethod = val);
                },
              ),
              SizedBox(height: 16.h),
              AppTextField(label: 'Transfer Reference (Required)', controller: refController),
              SizedBox(height: 16.h),
              AppTextField(label: 'Receipt URL (Optional)', controller: receiptController),
              SizedBox(height: 16.h),
              AppTextField(label: 'Notes (Optional)', controller: notesController),
            ],
          ),
          actions: [
            AppButton(
              text: 'Cancel',
              backgroundColor: AppColors.mutedBackground,
              foregroundColor: AppColors.textPrimary,
              onPressed: () => Navigator.pop(context),
            ),
            AppButton(
              text: 'Complete Payment',
              onPressed: () async {
                if (refController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transfer Reference is required!')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await sl<SupabaseClient>().rpc('complete_payout', params: {
                    'p_payout_id': payoutId,
                    'p_transfer_method': transferMethod,
                    'p_transfer_reference': refController.text.trim(),
                    'p_receipt_url': receiptController.text.trim().isEmpty ? null : receiptController.text.trim(),
                    'p_notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  });
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payout marked as paid successfully!')),
                  );
                  _fetchData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _actionWithReasonModal(String title, String rpcName, String payoutId) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        child: AppTextField(label: 'Reason / Notes', controller: reasonController),
        actions: [
          AppButton(
            text: 'Cancel',
            backgroundColor: AppColors.mutedBackground,
            foregroundColor: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            text: 'Confirm',
            onPressed: () async {
              Navigator.pop(context);
              try {
                await sl<SupabaseClient>().rpc(rpcName, params: {
                  'p_payout_id': payoutId,
                  'p_reason': reasonController.text.trim(),
                });
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action executed successfully!')));
                _fetchData();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _resolveReviewModal(String payoutId) async {
    String resolution = 'approve';
    final reasonController = TextEditingController(text: 'Verified manually with finance records');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: 'Resolve Payout Review',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This payout requires reconciliation before payment.', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              const Text('Resolution Action', style: TextStyle(color: AppColors.textSecondary)),
              DropdownButton<String>(
                value: resolution,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: AppColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'approve', child: Text('Approve & Move to Pending')),
                  DropdownMenuItem(value: 'cancel', child: Text('Cancel Payout')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => resolution = val);
                },
              ),
              SizedBox(height: 16.h),
              AppTextField(label: 'Reason / Notes', controller: reasonController),
            ],
          ),
          actions: [
            AppButton(
              text: 'Cancel',
              backgroundColor: AppColors.mutedBackground,
              foregroundColor: AppColors.textPrimary,
              onPressed: () => Navigator.pop(context),
            ),
            AppButton(
              text: 'Resolve',
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await sl<SupabaseClient>().rpc('resolve_payout_review', params: {
                    'p_payout_id': payoutId,
                    'p_resolution': resolution,
                    'p_reason': reasonController.text.trim(),
                  });
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout review resolved successfully!')));
                  _fetchData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
          ],
        ),
      ),
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
          title: 'Payout Details & Reconciliation',
          child: SizedBox(
            width: 500.w,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Status: ${details['payout']['status']}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  Text('Total Amount: \$${details['payout']['total_amount'] ?? details['payout']['amount']}', style: const TextStyle(color: AppColors.neonGreen)),
                  Text('Period: ${details['payout']['period_start']} to ${details['payout']['period_end']}'),
                  if (details['payout']['transfer_reference'] != null)
                    Text('Transfer Ref: ${details['payout']['transfer_reference']} (${details['payout']['transfer_method']})'),
                  SizedBox(height: 16.h),
                  const Text('Reconciliation Summary:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text('Total Payments: ${details['reconciliation']['payment_count']}'),
                  Text('Completed Count: ${details['reconciliation']['completed_count']}'),
                  Text('Calculated Net: \$${details['reconciliation']['calculated_net']}'),
                  Text('Difference: \$${details['reconciliation']['difference']}'),
                ],
              ),
            ),
          ),
          actions: [
            AppButton(
              text: 'Close',
              backgroundColor: AppColors.mutedBackground,
              foregroundColor: AppColors.textPrimary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            tabs: const [
              Tab(text: 'Pending Overview'),
              Tab(text: 'All Payouts History'),
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
                          ? Center(child: Text(AppStrings.noPendingPayouts, style: const TextStyle(color: AppColors.textSecondary)))
                          : DataTableWidget(
                              columns: ['Lounge', 'Pending Amount', 'Payments Count', 'Actions'],
                              rows: _pendingOverview.map((p) => DataRow(
                                cells: [
                                  DataCell(Text(p['lounge_name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
                                  DataCell(Text('\$${((p['pending_amount'] as num?) ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.neonGreen))),
                                  DataCell(Text((p['pending_payments_count'] ?? 0).toString(), style: const TextStyle(color: AppColors.textSecondary))),
                                  DataCell(
                                    AppButton(
                                      text: AppStrings.createPayout,
                                      onPressed: () => _createPayoutModal(p['lounge_id'], p['lounge_name']),
                                    ),
                                  ),
                                ],
                              )).toList(),
                            ),

                      // Tab 2: All Payouts
                      _allPayouts.isEmpty
                          ? Center(child: Text(AppStrings.noPayoutHistoryFound, style: const TextStyle(color: AppColors.textSecondary)))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTableWidget(
                                columns: [
                                  'Lounge',
                                  'Period Start',
                                  'Period End',
                                  'Total Amount',
                                  'Count',
                                  'Status',
                                  'Created At',
                                  'Paid At',
                                  'Transfer Ref',
                                  'Method',
                                  'Actions'
                                ],
                                rows: _allPayouts.map((p) {
                                  final status = p['status'] ?? 'pending';
                                  final createdAt = p['created_at'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(p['created_at'])) : '-';
                                  final paidAt = p['paid_at'] != null ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(p['paid_at'])) : '-';
                                  
                                  List<Widget> actionButtons = [];
                                  
                                  if (status == 'pending') {
                                    actionButtons.addAll([
                                      TextButton(
                                        onPressed: () async {
                                          await sl<SupabaseClient>().rpc('approve_payout', params: {'p_payout_id': p['id']});
                                          _fetchData();
                                        },
                                        child: const Text('Approve', style: TextStyle(color: Colors.blueAccent)),
                                      ),
                                      TextButton(
                                        onPressed: () => _actionWithReasonModal('Cancel Payout', 'cancel_payout', p['id']),
                                        child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ]);
                                  } else if (status == 'approved') {
                                    actionButtons.addAll([
                                      TextButton(
                                        onPressed: () async {
                                          await sl<SupabaseClient>().rpc('start_payout_processing', params: {'p_payout_id': p['id']});
                                          _fetchData();
                                        },
                                        child: const Text('Process', style: TextStyle(color: Colors.purpleAccent)),
                                      ),
                                      TextButton(
                                        onPressed: () => _completePayoutModal(p['id']),
                                        child: const Text('Pay', style: TextStyle(color: Colors.greenAccent)),
                                      ),
                                      TextButton(
                                        onPressed: () => _actionWithReasonModal('Mark Failed', 'fail_payout', p['id']),
                                        child: const Text('Fail', style: TextStyle(color: Colors.orangeAccent)),
                                      ),
                                    ]);
                                  } else if (status == 'processing') {
                                    actionButtons.addAll([
                                      TextButton(
                                        onPressed: () => _completePayoutModal(p['id']),
                                        child: const Text('Pay', style: TextStyle(color: Colors.greenAccent)),
                                      ),
                                      TextButton(
                                        onPressed: () => _actionWithReasonModal('Mark Failed', 'fail_payout', p['id']),
                                        child: const Text('Fail', style: TextStyle(color: Colors.orangeAccent)),
                                      ),
                                    ]);
                                  } else if (status == 'needs_review') {
                                    actionButtons.addAll([
                                      TextButton(
                                        onPressed: () => _resolveReviewModal(p['id']),
                                        child: const Text('Resolve', style: TextStyle(color: Colors.amberAccent)),
                                      ),
                                    ]);
                                  }

                                  actionButtons.add(
                                    TextButton(
                                      onPressed: () => _viewDetailsModal(p['id']),
                                      child: const Text('Details', style: TextStyle(color: AppColors.neonCyan)),
                                    ),
                                  );

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(p['lounges']?['name'] ?? '-', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
                                      DataCell(Text(p['period_start'] ?? '', style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(Text(p['period_end'] ?? '', style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(Text('\$${((p['total_amount'] as num?) ?? (p['amount'] as num?) ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.neonGreen))),
                                      DataCell(Text((p['payment_count'] ?? '-').toString(), style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(_buildStatusBadge(status)),
                                      DataCell(Text(createdAt, style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(Text(paidAt, style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(Text(p['transfer_reference'] ?? '-', style: const TextStyle(color: AppColors.textSecondary))),
                                      DataCell(Text(p['transfer_method'] ?? '-', style: const TextStyle(color: AppColors.textSecondary))),
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
