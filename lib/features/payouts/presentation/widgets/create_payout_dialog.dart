import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import '../../domain/repositories/payout_repository.dart';

class CreatePayoutDialog extends StatefulWidget {
  final String loungeId;
  final String loungeName;
  final VoidCallback onSuccess;

  const CreatePayoutDialog({
    super.key,
    required this.loungeId,
    required this.loungeName,
    required this.onSuccess,
  });

  @override
  State<CreatePayoutDialog> createState() => _CreatePayoutDialogState();
}

class _CreatePayoutDialogState extends State<CreatePayoutDialog> {
  final _startController = TextEditingController(text: '2026-01-01');
  late final TextEditingController _endController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _endController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final resultEither = await sl<PayoutRepository>().createPayout(
      loungeId: widget.loungeId,
      periodStart: _startController.text,
      periodEnd: _endController.text,
    );

    if (!mounted) return;

    resultEither.fold(
      (failure) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = failure.message;
        });
      },
      (result) {
        Navigator.pop(context);
        if (result['success'] == true) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '${AppStrings.payoutCreatedSuccess} \$${result['amount']} (${result['payment_count']} ${AppStrings.paymentsCount})',
              ),
            ),
          );
        }
        widget.onSuccess();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppStrings.createPayoutFor(widget.loungeName),
      actions: [
        AppButton(
          text: AppStrings.cancel,
          backgroundColor: AppColors.mutedBackground,
          foregroundColor: AppColors.textPrimary,
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        AppButton(
          text: AppStrings.create,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: AppStrings.periodStart, controller: _startController),
          SizedBox(height: 16.h),
          AppTextField(label: AppStrings.periodEnd, controller: _endController),
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
