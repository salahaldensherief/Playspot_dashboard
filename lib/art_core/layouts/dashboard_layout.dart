import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;
  final String? title; // Keep for backward compatibility or remove later
  final String? activeRoute;

  const DashboardLayout({
    super.key,
    required this.child,
    this.title,
    this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32.r),
      child: child,
    );
  }
}
