import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../../../art_core/widgets/app_text_field.dart';

class KycRejectionDialog extends StatefulWidget {
  const KycRejectionDialog({super.key});
  @override
  State<KycRejectionDialog> createState() => _KycRejectionDialogState();
}

class _KycRejectionDialogState extends State<KycRejectionDialog> {
  final _notes = TextEditingController();
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppDialog(
    title: AppStrings.rejectKyc,
    maxWidth: 440.w,
    actions: [
      AppButton(
        text: AppStrings.cancel,
        variant: AppButtonVariant.outlined,
        onPressed: () => Navigator.pop(context),
      ),
      AppButton(
        text: AppStrings.reject,
        variant: AppButtonVariant.danger,
        onPressed: _notes.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, _notes.text.trim()),
      ),
    ],
    child: AppTextField(
      controller: _notes,
      label: AppStrings.rejectReasonLabel,
      maxLines: 3,
      onChanged: (_) => setState(() {}),
    ),
  );
}
