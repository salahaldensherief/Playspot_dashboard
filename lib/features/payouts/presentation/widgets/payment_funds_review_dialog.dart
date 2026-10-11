import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import '../../domain/entities/payment_funds_review.dart';
import '../../domain/repositories/payout_repository.dart';
import 'record_payment_funds_dialog.dart';

class PaymentFundsReviewDialog extends StatefulWidget {
  final VoidCallback onChanged;
  const PaymentFundsReviewDialog({super.key, required this.onChanged});

  @override
  State<PaymentFundsReviewDialog> createState() =>
      _PaymentFundsReviewDialogState();
}

class _PaymentFundsReviewDialogState extends State<PaymentFundsReviewDialog> {
  List<PaymentFundsReview> _payments = const [];
  bool _loading = true;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await sl<PayoutRepository>().getPaymentFundsReview(
      offset: more ? _payments.length : 0,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (payments) => setState(() {
        _payments = more ? [..._payments, ...payments] : payments;
        _hasMore = payments.length == 50;
        _loading = false;
      }),
    );
  }

  Future<void> _review(PaymentFundsReview payment) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecordPaymentFundsDialog(payment: payment),
    );
    if (!mounted || saved != true) return;
    widget.onChanged();
    await _load();
  }

  @override
  Widget build(BuildContext context) => AppDialog(
    title: AppStrings.paymentFundsReview,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.paymentFundsReviewHelp),
        const SizedBox(height: 16),
        if (_error != null) ...[
          Text(_error ?? ''),
          AppButton(
            text: AppStrings.retry,
            onPressed: _loading ? null : () => _load(),
          ),
        ],
        if (!_loading && _error == null && _payments.isEmpty)
          Text(AppStrings.noDataFound),
        for (final payment in _payments)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(payment.id),
                  Text(
                    '${payment.amount.toStringAsFixed(2)} ${AppStrings.egp} · ${payment.paymentMethod}',
                  ),
                  Text(
                    '${AppStrings.lounge}: ${payment.loungeName ?? payment.loungeId}',
                  ),
                  Text(
                    DateFormat.yMd().add_Hm().format(payment.paidAt.toLocal()),
                  ),
                  if (payment.bookingId != null)
                    SelectableText(payment.bookingId ?? ''),
                  AppButton(
                    text: AppStrings.reviewFundsHolder,
                    onPressed: _loading ? null : () => _review(payment),
                  ),
                ],
              ),
            ),
          ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_hasMore && !_loading && _error == null)
          AppButton(
            text: AppStrings.loadMore,
            onPressed: () => _load(more: true),
          ),
      ],
    ),
  );
}
