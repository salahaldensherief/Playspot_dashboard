import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dashboard_sidebar.dart';
import 'dashboard_top_bar.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  final String location;

  const DashboardShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    // Logic to determine active route for the sidebar
    String activeRoute = '';
    String title = 'Dashboard';

    if (location.contains('dashboard')) {
      activeRoute = AppStrings.dashboard;
      title = 'Command & Control';
    } else if (location.contains('lounges')) {
      activeRoute = AppStrings.lounges;
      title = 'Lounge Management';
    } else if (location.contains('rooms')) {
      activeRoute = 'Rooms';
      title = 'Room Management';
    } else if (location.contains('live-operations')) {
      activeRoute = AppStrings.bookings;
      title = 'Live Operations';
    } else if (location.contains('users')) {
      activeRoute = 'Users';
      title = 'User Management';
    }

    return Scaffold(
      body: Row(
        children: [
          DashboardSidebar(activeRoute: activeRoute),
          Expanded(
            child: Column(
              children: [
                DashboardTopBar(title: title),
                Expanded(
                  child: child, // child is the page content
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
