import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

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
    return AppDialog(
      title: AppStrings.newSupportTicket,
      width: 440.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _issueType,
            dropdownColor: AppColors.cardBackground,
            decoration: InputDecoration(labelText: AppStrings.issueType),
            items: [
              DropdownMenuItem(value: 'general', child: Text(AppStrings.issueTypeGeneral)),
              DropdownMenuItem(value: 'booking', child: Text(AppStrings.issueTypeBooking)),
              DropdownMenuItem(value: 'payment', child: Text(AppStrings.issueTypePayment)),
              DropdownMenuItem(value: 'technical', child: Text(AppStrings.issueTypeTechnical)),
            ],
            onChanged: _submitting ? null : (value) => setState(() => _issueType = value ?? 'general'),
          ),
          SizedBox(height: 16.h),
          AppTextField(
            controller: _messageController,
            maxLines: 5,
            maxLength: 2000,
            labelText: AppStrings.message,
          ),
        ],
      ),
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
    );
  }
}
