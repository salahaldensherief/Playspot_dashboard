import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
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
      await widget.onConfirm(double.parse(_controller.text));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isDismissible && !_submitting,
      child: AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.vpn_key_outlined, color: AppColors.neonBlue, size: 24.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                AppStrings.openNewShift,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  fontFamilyFallback: const ['Tajawal'],
                ),
              ),
            ),
          ],
        ),
        content: Form(
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
                  if (val == null || val.isEmpty)
                    return AppStrings.fieldRequired;
                  final amount = double.tryParse(val);
                  if (amount == null || !amount.isFinite || amount < 0)
                    return AppStrings.invalidNumber;
                  return null;
                },
              ),
            ],
          ),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
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
          SizedBox(width: 8.w),
          AppButton(
            text: AppStrings.openNewShift,
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
