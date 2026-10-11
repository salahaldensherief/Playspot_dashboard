import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import '../../domain/entities/payment_funds_review.dart';
import '../../domain/repositories/payout_repository.dart';

class RecordPaymentFundsDialog extends StatefulWidget {
  final PaymentFundsReview payment;
  const RecordPaymentFundsDialog({super.key, required this.payment});

  @override
  State<RecordPaymentFundsDialog> createState() =>
      _RecordPaymentFundsDialogState();
}

class _RecordPaymentFundsDialogState extends State<RecordPaymentFundsDialog> {
  final _form = GlobalKey<FormState>();
  final _evidence = TextEditingController();
  PaymentFundsHolder? _holder;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _evidence.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final holder = _holder;
    if (holder == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await sl<PayoutRepository>().recordPaymentFundsCustody(
      paymentId: widget.payment.id,
      holder: holder,
      evidenceReference: _evidence.text.trim(),
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      (_) => Navigator.pop(context, true),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AppDialog(
      title: AppStrings.reviewFundsHolder,
      showCloseIcon: false,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        AppButton(
          text: AppStrings.save,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(widget.payment.id),
            Text(
              '${widget.payment.amount.toStringAsFixed(2)} ${AppStrings.egp}',
            ),
            const SizedBox(height: 12),
            Text(AppStrings.fundsCustodyImmutableHelp),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentFundsHolder>(
              isExpanded: true,
              decoration: InputDecoration(labelText: AppStrings.fundsHolder),
              items: [
                DropdownMenuItem(
                  value: PaymentFundsHolder.platform,
                  child: Text(AppStrings.fundsReceivedByPlatform),
                ),
                DropdownMenuItem(
                  value: PaymentFundsHolder.lounge,
                  child: Text(AppStrings.fundsReceivedByLounge),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _holder = value),
              validator: (value) =>
                  value == null ? AppStrings.selectFundsHolder : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _evidence,
              enabled: !_saving,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: AppStrings.fundsEvidenceReference,
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? AppStrings.fundsEvidenceRequired
                  : null,
            ),
            if (_error != null)
              Text(
                _error ?? '',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
  );
}
