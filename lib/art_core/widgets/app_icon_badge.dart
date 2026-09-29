import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

/// Reusable icon badge widget with tinted background and matching subtle border.
class AppIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double? size;
  final double? iconSize;
  final double? borderRadius;
  final VoidCallback? onTap;
  final String? tooltip;

  const AppIconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.neonBlue,
    this.size,
    this.iconSize,
    this.borderRadius,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final double boxSize = size ?? 36.r;
    final double glyphSize = iconSize ?? (boxSize * 0.52);
    final double radius = borderRadius ?? 8.r;

    Widget badge = Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Center(
        child: Icon(
          icon,
          size: glyphSize,
          color: color,
        ),
      ),
    );

    if (onTap != null) {
      badge = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: badge,
        ),
      );
    }

    if (tooltip != null && tooltip!.trim().isNotEmpty) {
      badge = Tooltip(
        message: tooltip!,
        child: badge,
      );
    }

    return badge;
  }
}
