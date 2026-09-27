import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import '../../domain/repositories/payout_repository.dart';

class CompletePayoutDialog extends StatefulWidget {
  final String payoutId;
  final VoidCallback onSuccess;

  const CompletePayoutDialog({
    super.key,
    required this.payoutId,
    required this.onSuccess,
  });

  @override
  State<CompletePayoutDialog> createState() => _CompletePayoutDialogState();
}

class _CompletePayoutDialogState extends State<CompletePayoutDialog> {
  String _transferMethod = 'instapay';
  final _refController = TextEditingController();
  final _receiptController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _refController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_refController.text.trim().isEmpty) {
      setState(() => _errorMessage = AppStrings.transferRefRequiredError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final resultEither = await sl<PayoutRepository>().completePayout(
      payoutId: widget.payoutId,
      transferMethod: _transferMethod,
      transferReference: _refController.text.trim(),
      receiptUrl: _receiptController.text.trim().isEmpty ? null : _receiptController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;

    resultEither.fold(
      (failure) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = failure.message;
        });
      },
      (_) {
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(content: Text(AppStrings.payoutMarkedPaidSuccess)),
        );
        widget.onSuccess();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppStrings.completePayoutPayment,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          backgroundColor: AppColors.mutedBackground,
          foregroundColor: AppColors.textPrimary,
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        AppButton(
          text: AppStrings.completePayment,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.transferMethod, style: const TextStyle(color: AppColors.textSecondary)),
          DropdownButton<String>(
            value: _transferMethod,
            dropdownColor: AppColors.cardBackground,
            style: const TextStyle(color: AppColors.textPrimary),
            items: ['bank_transfer', 'instapay', 'vodafone_cash', 'cash', 'other']
                .map((m) => DropdownMenuItem(value: m, child: Text(m.toUpperCase())))
                .toList(),
            onChanged: _isSubmitting
                ? null
                : (val) {
                    if (val != null) setState(() => _transferMethod = val);
                  },
          ),
          SizedBox(height: 16.h),
          AppTextField(label: AppStrings.transferRefRequired, controller: _refController),
          SizedBox(height: 16.h),
          AppTextField(label: AppStrings.receiptUrlOptional, controller: _receiptController),
          SizedBox(height: 16.h),
          AppTextField(label: AppStrings.notesOptional, controller: _notesController),
          if (_errorMessage != null) ...[
            SizedBox(height: 12.h),
            Text(
              _errorMessage ?? '',
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
