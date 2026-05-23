import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
  });

  factory StatusBadge.success(String text) => StatusBadge(text: text, color: AppColors.success);
  factory StatusBadge.warning(String text) => StatusBadge(text: text, color: AppColors.warning);
  factory StatusBadge.danger(String text) => StatusBadge(text: text, color: AppColors.danger);
  factory StatusBadge.info(String text) => StatusBadge(text: text, color: AppColors.neonBlue);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
