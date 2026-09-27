import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import '../../domain/repositories/payout_repository.dart';

class PayoutReasonDialog extends StatefulWidget {
  final String title;
  final String rpcName;
  final String payoutId;
  final VoidCallback onSuccess;

  const PayoutReasonDialog({
    super.key,
    required this.title,
    required this.rpcName,
    required this.payoutId,
    required this.onSuccess,
  });

  @override
  State<PayoutReasonDialog> createState() => _PayoutReasonDialogState();
}

class _PayoutReasonDialogState extends State<PayoutReasonDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final repo = sl<PayoutRepository>();
    final reason = _reasonController.text.trim();

    final result = widget.rpcName == 'approve_payout'
        ? await repo.approvePayout(payoutId: widget.payoutId, notes: reason)
        : widget.rpcName == 'fail_payout'
            ? await repo.failPayout(payoutId: widget.payoutId, reason: reason)
            : await repo.cancelPayout(payoutId: widget.payoutId, reason: reason);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = failure.message;
        });
      },
      (_) {
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(content: Text(AppStrings.actionExecutedSuccess)));
        widget.onSuccess();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          backgroundColor: AppColors.mutedBackground,
          foregroundColor: AppColors.textPrimary,
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        AppButton(
          text: AppStrings.confirm,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: AppStrings.reasonNotes, controller: _reasonController),
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
