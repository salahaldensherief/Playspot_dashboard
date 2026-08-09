import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'dashboard_sidebar.dart';
import 'dashboard_top_bar.dart';

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
    String activeRoute = '';
    String title = AppStrings.dashboard;

    if (location.contains('dashboard')) {
      activeRoute = AppStrings.dashboard;
      title = AppStrings.systemOverview;
    } else if (location.contains('lounges')) {
      activeRoute = AppStrings.lounges;
      title = AppStrings.lounges;
    } else if (location.contains('rooms')) {
      activeRoute = AppStrings.rooms;
      title = AppStrings.manageRoomsDesc;
    } else if (location.contains('live-operations')) {
      activeRoute = AppStrings.bookings;
      title = AppStrings.liveBookingsFeed;
    } else if (location.contains('users')) {
      activeRoute = AppStrings.users;
      title = AppStrings.loungeAdministrators;
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
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
