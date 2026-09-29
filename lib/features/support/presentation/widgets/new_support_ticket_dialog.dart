import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';

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
    final isArabic = context.locale.languageCode == 'ar';
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Text(isArabic ? 'تذكرة دعم جديدة' : 'New support ticket',
          style: const TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 420.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _issueType,
              dropdownColor: AppColors.cardBackground,
              decoration: InputDecoration(labelText: AppStrings.issueType),
              items: [
                DropdownMenuItem(value: 'general', child: Text(isArabic ? 'عام' : 'General')),
                DropdownMenuItem(value: 'booking', child: Text(isArabic ? 'حجز' : 'Booking')),
                DropdownMenuItem(value: 'payment', child: Text(isArabic ? 'دفع' : 'Payment')),
                DropdownMenuItem(value: 'technical', child: Text(isArabic ? 'تقني' : 'Technical')),
              ],
              onChanged: _submitting ? null : (value) => setState(() => _issueType = value ?? 'general'),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _messageController,
              maxLines: 5,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: AppStrings.message,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
        AppButton(
          text: AppStrings.create,
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
