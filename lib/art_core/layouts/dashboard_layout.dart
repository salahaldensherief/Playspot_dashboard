import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/core/responsive/app_breakpoints.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;
  final String? title; // Keep for backward compatibility or remove later
  final String? activeRoute;
  final bool isScrollable;

  const DashboardLayout({
    super.key,
    required this.child,
    this.title,
    this.activeRoute,
    this.isScrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = AppBreakpoints.isMobile(context)
        ? 12.w
        : (AppBreakpoints.isTablet(context) ? 20.w : 28.r);

    final double verticalPadding = AppBreakpoints.isMobile(context)
        ? 12.h
        : (AppBreakpoints.isTablet(context) ? 20.h : 28.r);

    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: child,
    );

    if (isScrollable) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: body,
      );
    }

    return body;
  }
}
