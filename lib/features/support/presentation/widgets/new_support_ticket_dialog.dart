import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';

class NewSupportTicketDialog extends StatefulWidget {
  final Future<bool> Function(String issueType, String message) onSubmit;

  const NewSupportTicketDialog({super.key, required this.onSubmit});

  @override
  State<NewSupportTicketDialog> createState() => _NewSupportTicketDialogState();
}

class _NewSupportTicketDialogState extends State<NewSupportTicketDialog> {
  final _messageController = TextEditingController();
  String _issueType = 'general';
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final success = await widget.onSubmit(_issueType, message);
      if (mounted && success) Navigator.of(context).pop(true);
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.actionFailed), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return AppDialog(
      title: AppStrings.newSupportTicket,
      icon: Icons.support_agent,
      width: 500.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: AppStrings.create,
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _issueType,
            dropdownColor: AppColors.cardBackground,
            decoration: InputDecoration(
              labelText: AppStrings.issueType,
              filled: true,
              fillColor: AppColors.scaffoldBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            items: [
              DropdownMenuItem(value: 'general', child: Text(AppStrings.issueCategoryGeneral)),
              DropdownMenuItem(value: 'booking', child: Text(AppStrings.issueCategoryBooking)),
              DropdownMenuItem(value: 'payment', child: Text(AppStrings.issueCategoryPayment)),
              DropdownMenuItem(value: 'technical', child: Text(AppStrings.issueCategoryTechnical)),
            ],
            onChanged: _submitting ? null : (value) => setState(() => _issueType = value ?? 'general'),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _messageController,
            maxLines: 5,
            maxLength: 2000,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(
              labelText: AppStrings.message,
              filled: true,
              fillColor: AppColors.scaffoldBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
    );
  }
}
