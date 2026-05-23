import 'package:flutter/material.dart';
import '../../../../art_core/widgets/dashboard_layout.dart';
import '../../../../art_core/widgets/stat_card.dart';
import '../../../../art_core/widgets/data_table_widget.dart';
import '../../../../art_core/widgets/status_badge.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Super Admin Dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Revenue',
                  value: 'EGP 124,500',
                  change: '+12.5%',
                  isPositive: true,
                  icon: Icons.payments_outlined,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: StatCard(
                  title: 'Total Bookings',
                  value: '1,240',
                  change: '+8.2%',
                  isPositive: true,
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: StatCard(
                  title: 'Active Lounges',
                  value: '45',
                  change: '+2',
                  isPositive: true,
                  icon: Icons.storefront_outlined,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: StatCard(
                  title: 'Total Users',
                  value: '8,920',
                  change: '+15.4%',
                  isPositive: true,
                  icon: Icons.people_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Recent Bookings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          DataTableWidget(
            columns: const ['Booking ID', 'User', 'Lounge', 'Date', 'Amount', 'Status'],
            rows: [
              DataRow(cells: [
                const DataCell(Text('#BK-7281', style: TextStyle(color: Colors.white))),
                const DataCell(Text('Ahmed Mohamed', style: TextStyle(color: Colors.white))),
                const DataCell(Text('Game Zone Dokki', style: TextStyle(color: Colors.white))),
                const DataCell(Text('Oct 24, 2023', style: TextStyle(color: Colors.white))),
                const DataCell(Text('EGP 150', style: TextStyle(color: Colors.white))),
                DataCell(StatusBadge.success('Completed')),
              ]),
              DataRow(cells: [
                const DataCell(Text('#BK-7282', style: TextStyle(color: Colors.white))),
                const DataCell(Text('Sara Ali', style: TextStyle(color: Colors.white))),
                const DataCell(Text('Nexus Gaming', style: TextStyle(color: Colors.white))),
                const DataCell(Text('Oct 24, 2023', style: TextStyle(color: Colors.white))),
                const DataCell(Text('EGP 200', style: TextStyle(color: Colors.white))),
                DataCell(StatusBadge.warning('Pending')),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
