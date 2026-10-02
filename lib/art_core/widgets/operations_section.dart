import 'package:flutter/material.dart';
import '../theme/operations_tokens.dart';

class OperationsSection extends StatelessWidget {
  final String title;
  final Widget child;
  const OperationsSection({
    super.key,
    required this.title,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: OperationsTokens.gap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: OperationsTokens.sectionTitle),
        const SizedBox(height: OperationsTokens.gap),
        child,
      ],
    ),
  );
}
