import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';

class OpenShiftDialog extends StatefulWidget {
  final FutureOr<void> Function(double) onConfirm;
  final bool isDismissible;

  const OpenShiftDialog({
    super.key,
    required this.onConfirm,
    this.isDismissible = false,
  });

  @override
  State<OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends State<OpenShiftDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final amount = double.tryParse(_controller.text.trim()) ?? 0.0;
      await widget.onConfirm(amount);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isDismissible && !_submitting,
      child: AppDialog(
        title: AppStrings.openNewShift,
        icon: Icons.vpn_key_outlined,
        maxWidth: 440.w,
        actions: [
          if (widget.isDismissible)
            AppButton(
              text: AppStrings.cancel,
              variant: AppButtonVariant.outlined,
              onPressed: _submitting ? null : () => Navigator.pop(context),
            )
          else
            AppButton(
              text: AppStrings.logout,
              icon: Icons.logout,
              variant: AppButtonVariant.danger,
              onPressed: _submitting
                  ? null
                  : () {
                      Navigator.pop(context);
                      context.read<LoginCubit>().logout();
                    },
            ),
          AppButton(
            text: AppStrings.openNewShift,
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.noActiveShift,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 24.h),
              AppTextField(
                controller: _controller,
                label: AppStrings.startingCash,
                hintText: AppStrings.hintAmount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  final amount = double.tryParse(val);
                  if (amount == null || !amount.isFinite || amount < 0) {
                    return AppStrings.invalidNumber;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
