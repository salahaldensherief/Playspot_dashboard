import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppColors.sidebarActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: isActive
              ? Border.all(
                  color: AppColors.sidebarActiveBorder.withValues(alpha: 0.5))
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r)),
          child: ListTile(
            leading: Icon(
              icon,
              color: isActive ? AppColors.neonBlue : AppColors.textSecondary,
              size: 20.r,
            ),
            title: Text(
              label,
              style: TextStyle(
                color:
                    isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            onTap: () {
              if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                Navigator.of(context).pop();
              }
              onTap();
            },
            dense: true,
          ),
        ),
      ),
    );
  }
}
