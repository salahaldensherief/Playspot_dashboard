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

  static bool isMobile(BuildContext context) => AppBreakpoints.isMobile(context);

  static bool isTablet(BuildContext context) => AppBreakpoints.isTablet(context);

  static bool isDesktop(BuildContext context) => AppBreakpoints.isDesktop(context);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.desktopMin) {
      return desktop;
    } else if (width >= AppBreakpoints.mobileMax && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
