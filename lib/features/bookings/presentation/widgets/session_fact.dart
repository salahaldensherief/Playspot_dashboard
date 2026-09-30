import 'package:flutter/material.dart';
import '../../../../art_core/theme/operations_tokens.dart';

class SessionFact extends StatelessWidget {
  final String label;
  final String value;
  const SessionFact({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: OperationsTokens.gap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OperationsTokens.label),
        Text(value, style: OperationsTokens.value),
      ],
    ),
  );
}
