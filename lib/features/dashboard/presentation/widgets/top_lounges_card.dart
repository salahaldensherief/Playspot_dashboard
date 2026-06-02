import 'package:flutter/material.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';

class TopLoungesCard extends StatelessWidget {
  const TopLoungesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.topPerformingLounges,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.topPerformingLoungesSubtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          // Simplified table/list for now
          _LoungeItem(name: 'Nexus Gaming Zone', bookings: 1240, revenue: '\$15,200', trend: '+12%'),
          const Divider(color: AppColors.borderDefault, height: 24),
          _LoungeItem(name: 'The Arena', bookings: 980, revenue: '\$12,800', trend: '+8%'),
          const Divider(color: AppColors.borderDefault, height: 24),
          _LoungeItem(name: 'Cyber Pulse', bookings: 850, revenue: '\$10,500', trend: '+15%'),
        ],
      ),
    );
  }
}

class _LoungeItem extends StatelessWidget {
  final String name;
  final int bookings;
  final String revenue;
  final String trend;

  const _LoungeItem({
    required this.name,
    required this.bookings,
    required this.revenue,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.mutedBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.business, color: AppColors.neonBlue, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(
            name,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bookings', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text('$bookings', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Revenue', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text(revenue, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        Text(
          trend,
          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
