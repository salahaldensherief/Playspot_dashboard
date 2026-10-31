import 'package:flutter/material.dart';
import '../theme/operations_tokens.dart';

class OperationsFactsGrid extends StatelessWidget {
  final List<Widget> children;
  const OperationsFactsGrid({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      if (width <= 0 || children.isEmpty) return const SizedBox.shrink();
      final scale =
          (MediaQuery.textScalerOf(
                    context,
                  ).scale(OperationsTokens.valueFontSize) /
                  OperationsTokens.valueFontSize)
              .clamp(1.0, 3.0);
      final columns = (width / (OperationsTokens.factMinimumWidth * scale))
          .floor()
          .clamp(1, 2);
      final itemWidth =
          (width - OperationsTokens.gap * (columns - 1)) / columns;
      return Wrap(
        spacing: OperationsTokens.gap,
        runSpacing: OperationsTokens.gap,
        children: [
          for (final child in children)
            SizedBox(width: itemWidth, child: child),
        ],
      );
    },
  );
}
