import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

class StopConfirmationDialog extends StatefulWidget {
  const StopConfirmationDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const StopConfirmationDialog(),
    );
  }

  @override
  State<StopConfirmationDialog> createState() => _StopConfirmationDialogState();
}

class _StopConfirmationDialogState extends State<StopConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    setState(() {
      _canConfirm = text.trim() == 'STOP';
    });
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return AppDialog(
      title: AppStrings.confirmMaintenanceTitle,
      icon: Icons.warning_amber_rounded,
      width: 500.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context, false),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: AppStrings.enableMaintenanceNow,
          backgroundColor: _canConfirm ? AppColors.danger : AppColors.mutedBackground,
          foregroundColor: _canConfirm ? AppColors.textPrimary : AppColors.textMuted,
          onPressed: _canConfirm ? () => Navigator.pop(context, true) : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.confirmMaintenanceWarning,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            AppStrings.confirmMaintenanceHint,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 12.h),
          AppTextField(
            controller: _controller,
            hintText: AppStrings.confirmStopHintInput,
            onChanged: _onTextChanged,
          ),
        ],
      ),
    );
  }
}
