import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import '../../domain/repositories/payout_repository.dart';

class ResolvePayoutReviewDialog extends StatefulWidget {
  final String payoutId;
  final VoidCallback onSuccess;

  const ResolvePayoutReviewDialog({
    super.key,
    required this.payoutId,
    required this.onSuccess,
  });

  @override
  State<ResolvePayoutReviewDialog> createState() => _ResolvePayoutReviewDialogState();
}

class _ResolvePayoutReviewDialogState extends State<ResolvePayoutReviewDialog> {
  String _resolution = 'approve';
  final _reasonController = TextEditingController(text: 'Verified manually with finance records');
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
    final result = await sl<PayoutRepository>().resolvePayoutReview(
      payoutId: widget.payoutId,
      resolution: _resolution,
      reason: _reasonController.text.trim(),
    );

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
        messenger.showSnackBar(
          SnackBar(content: Text(AppStrings.payoutReviewResolvedSuccess)),
        );
        widget.onSuccess();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppStrings.resolvePayoutReview,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          backgroundColor: AppColors.mutedBackground,
          foregroundColor: AppColors.textPrimary,
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        AppButton(
          text: AppStrings.resolve,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.reconciliationWarning,
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Text(AppStrings.resolutionAction, style: const TextStyle(color: AppColors.textSecondary)),
          DropdownButton<String>(
            value: _resolution,
            dropdownColor: AppColors.cardBackground,
            style: const TextStyle(color: AppColors.textPrimary),
            items: [
              DropdownMenuItem(value: 'approve', child: Text(AppStrings.approveAndMoveToPending)),
              DropdownMenuItem(value: 'cancel', child: Text(AppStrings.cancelPayout)),
            ],
            onChanged: _isSubmitting
                ? null
                : (val) {
                    if (val != null) setState(() => _resolution = val);
                  },
          ),
          SizedBox(height: 16.h),
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
