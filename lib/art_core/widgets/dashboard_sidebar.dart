import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'PLAYSPOT',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.neonBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 40),
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            isActive: true,
            onTap: () {},
          ),
          _SidebarItem(
            icon: Icons.storefront_outlined,
            title: 'Lounges',
            onTap: () {},
          ),
          _SidebarItem(
            icon: Icons.people_outline,
            title: 'Users',
            onTap: () {},
          ),
          _SidebarItem(
            icon: Icons.book_online_outlined,
            title: 'Bookings',
            onTap: () {},
          ),
          _SidebarItem(
            icon: Icons.payments_outlined,
            title: 'Payments',
            onTap: () {},
          ),
          const Spacer(),
          _SidebarItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isActive ? AppColors.neonBlue : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
    );
  }
}
