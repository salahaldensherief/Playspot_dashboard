import 'package:flutter/material.dart';

/// Keep dashboard metrics wide enough to read on desktop and tablet.
class DashboardKpiLayout extends StatelessWidget {
  const DashboardKpiLayout({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final maxColumns = constraints.maxWidth >= 1600 ? 4 : 3;
      final columns = ((constraints.maxWidth + 12) / (250 * scale + 12))
          .floor()
          .clamp(
            1,
            children.isEmpty ? 1 : children.length.clamp(1, maxColumns),
          );
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
