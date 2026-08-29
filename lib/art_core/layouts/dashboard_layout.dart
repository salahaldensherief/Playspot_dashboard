import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final body = Padding(
      padding: EdgeInsets.all(32.r),
      child: child,
    );

    if (isScrollable) {
      return SingleChildScrollView(
        child: body,
      );
    }

    return body;
  }
}
