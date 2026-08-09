import 'package:flutter/material.dart';
import 'dashboard_sidebar.dart';
import 'dashboard_top_bar.dart';

class DashboardLayout extends StatelessWidget {
  final String title;
  final Widget child;

  const DashboardLayout({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
           DashboardSidebar(activeRoute: '',),
          Expanded(
            child: Column(
              children: [
                DashboardTopBar(title: title),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
