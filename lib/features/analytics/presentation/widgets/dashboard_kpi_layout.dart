import 'package:flutter/material.dart';

/// KPI labels stay readable: extra text scale reduces the column count.
class DashboardKpiLayout extends StatelessWidget {
  const DashboardKpiLayout({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final columns = ((constraints.maxWidth + 12) / (176 * scale + 12))
          .floor()
          .clamp(1, children.isEmpty ? 1 : children.length.clamp(1, 6));
      final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final child in children)
            SizedBox(
              width: width,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 128 * scale),
                child: child,
              ),
            ),
        ],
      );
    },
  );
}
