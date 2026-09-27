import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

/// Small pill used for duration, play mode, controllers, screen size, discount.
class BookingInfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool bordered;

  const BookingInfoChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: bordered ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.r, color: color),
            SizedBox(width: 3.w),
          ],
          Flexible(
            child: AppText.body(
              label,
              fontSize: 10.5.sp,
              color: color,
              fontWeight: FontWeight.w600,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
