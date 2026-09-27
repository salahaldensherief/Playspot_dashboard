import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;
  static const double desktopMin = 1024.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileMax &&
      MediaQuery.sizeOf(context).width < tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopMin;

  static bool isMobileWidth(double width) => width < mobileMax;
  static bool isTabletWidth(double width) => width >= mobileMax && width < tabletMax;
  static bool isDesktopWidth(double width) => width >= desktopMin;
}
