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
          .clamp(1, 6);
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        addSemanticIndexes: false,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 128 * scale,
        ),
        children: children,
      );
    },
  );
}
