import 'package:flutter/material.dart';
import 'lounge_dashboard_sections.dart';

class TabletLoungeDashboardContent extends StatelessWidget {
  const TabletLoungeDashboardContent({super.key, required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) =>
      LoungeDashboardSections(onRefresh: onRefresh);
}
