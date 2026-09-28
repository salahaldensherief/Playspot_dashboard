import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      AppBreakpoints.isMobile(context);

  static bool isTablet(BuildContext context) =>
      AppBreakpoints.isTablet(context);

  static bool isDesktop(BuildContext context) =>
      AppBreakpoints.isDesktop(context);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.desktopMin) {
          return desktop;
        } else if (constraints.maxWidth >= AppBreakpoints.mobileMax &&
            tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

extension ResponsiveContextX on BuildContext {
  bool get isMobile => AppBreakpoints.isMobile(this);
  bool get isTablet => AppBreakpoints.isTablet(this);
  bool get isDesktop => AppBreakpoints.isDesktop(this);

  T responsive<T>({required T mobile, T? tablet, required T desktop}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet ?? desktop;
    return mobile;
  }
}
