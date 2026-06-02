import 'package:flutter/material.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';

class DashboardSidebar extends StatelessWidget {
  final String activeRoute;
  const DashboardSidebar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sports_esports, color: AppColors.neonBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PlaySpot',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      AppStrings.superAdmin,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Menu Items
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: AppStrings.dashboard,
            isActive: activeRoute == AppStrings.dashboard,
          ),
          _SidebarItem(
            icon: Icons.business_outlined,
            label: AppStrings.lounges,
            isActive: activeRoute == AppStrings.lounges,
          ),
          _SidebarItem(
            icon: Icons.people_outline,
            label: AppStrings.users,
            isActive: activeRoute == AppStrings.users,
          ),
          _SidebarItem(
            icon: Icons.calendar_today_outlined,
            label: AppStrings.bookings,
            isActive: activeRoute == AppStrings.bookings,
          ),
          _SidebarItem(
            icon: Icons.payments_outlined,
            label: AppStrings.payments,
            isActive: activeRoute == AppStrings.payments,
          ),
          _SidebarItem(
            icon: Icons.settings_outlined,
            label: AppStrings.settings,
            isActive: activeRoute == AppStrings.settings,
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppColors.sidebarActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive 
            ? Border.all(color: AppColors.sidebarActiveBorder.withOpacity(0.5))
            : null,
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.sidebarActiveBorder.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ] : null,
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isActive ? AppColors.neonBlue : AppColors.textSecondary,
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          onTap: () {},
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
