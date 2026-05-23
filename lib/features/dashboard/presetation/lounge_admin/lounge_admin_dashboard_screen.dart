import 'package:flutter/material.dart';
import '../../../../art_core/widgets/dashboard_layout.dart';
import '../../../../art_core/widgets/stat_card.dart';

class LoungeAdminDashboardScreen extends StatelessWidget {
  const LoungeAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardLayout(
      title: 'Lounge Admin Dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Daily Revenue',
                  value: 'EGP 1,200',
                  change: '+5.5%',
                  isPositive: true,
                  icon: Icons.payments_outlined,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: StatCard(
                  title: 'Today\'s Bookings',
                  value: '12',
                  change: '-2%',
                  isPositive: false,
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: StatCard(
                  title: 'Available Rooms',
                  value: '4/6',
                  change: 'Stable',
                  isPositive: true,
                  icon: Icons.meeting_room_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
