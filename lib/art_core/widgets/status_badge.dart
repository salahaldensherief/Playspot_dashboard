import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  factory StatusBadge.neutral(String text) => StatusBadge(text: text, color: AppColors.textSecondary);
  factory StatusBadge.secondary(String text) => StatusBadge(text: text, color: AppColors.neonPurple);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
