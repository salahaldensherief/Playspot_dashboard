import 'package:flutter/material.dart';

/// Each column flows independently: a tall sidebar never pads the main feed.
/// Use available content width (after navigation), including text scaling.
class DashboardFlowLayout extends StatelessWidget {
  const DashboardFlowLayout({
    super.key,
    required this.main,
    required this.aside,
    this.compact,
  });

  final List<Widget> main;
  final List<Widget> aside;
  final List<Widget>? compact;
  static const gap = 16.0;

  Widget _column(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: gap),
        children[i],
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
      if (constraints.maxWidth < 900 * textScale.clamp(1, 1.6)) {
        return _column(compact ?? [...main, ...aside]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: _column(main)),
          const SizedBox(width: gap),
          Expanded(flex: 5, child: _column(aside)),
        ],
      );
    },
  );
}
