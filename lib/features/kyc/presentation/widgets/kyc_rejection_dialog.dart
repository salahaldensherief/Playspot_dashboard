import 'package:flutter/material.dart';
import '../../../../art_core/app_strings.dart';

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
  Widget build(BuildContext context) => AlertDialog(
    title: Text(AppStrings.rejectKyc),
    content: TextField(
      controller: _notes,
      maxLines: 3,
      decoration: InputDecoration(labelText: AppStrings.rejectReasonLabel),
      onChanged: (_) => setState(() {}),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppStrings.cancel),
      ),
      FilledButton(
        onPressed: _notes.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, _notes.text.trim()),
        child: Text(AppStrings.reject),
      ),
    ],
  );
}
