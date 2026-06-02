import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const DashboardTopBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  static const double _defaultHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _defaultHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Orbitron',
            ),
          ),
          const Spacer(),
          _buildSearchField(),
          const SizedBox(width: 24),
          if (actions != null) ...[
            ...actions!,
            const SizedBox(width: 24),
          ] else ...[
            const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
            const SizedBox(width: 24),
          ],
          _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 300,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: const TextField(
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 10), // Adjust alignment
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return const CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.neonPurple,
      child: Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_defaultHeight);
}
