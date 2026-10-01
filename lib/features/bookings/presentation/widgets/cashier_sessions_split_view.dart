import 'package:flutter/material.dart';
import '../../../../core/responsive/app_breakpoints.dart';
import '../../../../art_core/theme/operations_tokens.dart';

class CashierSessionsSplitView extends StatelessWidget {
  final Widget rail;
  final Widget details;
  final String sessionId;
  const CashierSessionsSplitView({
    super.key,
    required this.rail,
    required this.details,
    required this.sessionId,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = MediaQuery.sizeOf(context);
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : size.width;
      final height = constraints.hasBoundedHeight
          ? constraints.maxHeight
          : (size.height * OperationsTokens.panelViewportFraction).clamp(
              OperationsTokens.panelHeight,
              double.infinity,
            );
      if (width <= 0 || height <= 0) return const SizedBox.shrink();
      final railWidth = AppBreakpoints.isDesktopWidth(width)
          ? OperationsTokens.railWidth
          : width * 0.4;
      return SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: railWidth, child: rail),
            const SizedBox(width: OperationsTokens.gap),
            Expanded(
              child: RepaintBoundary(
                child: SingleChildScrollView(
                  key: ValueKey(sessionId),
                  child: details,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
