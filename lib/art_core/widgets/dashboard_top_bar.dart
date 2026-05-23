import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const DashboardTopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 24),
          const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
          const SizedBox(width: 24),
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.neonPurple,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
