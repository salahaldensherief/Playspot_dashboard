import 'package:flutter/material.dart';
import 'lounge_dashboard_sections.dart';

class DesktopLoungeDashboardContent extends StatelessWidget {
  const DesktopLoungeDashboardContent({super.key, required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) =>
      LoungeDashboardSections(onRefresh: onRefresh);
}
