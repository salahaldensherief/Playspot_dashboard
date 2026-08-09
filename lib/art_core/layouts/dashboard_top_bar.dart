import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  static double get _defaultHeight => 64.h;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _defaultHeight,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
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
            SizedBox(width: 16.w),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Orbitron',
            ),
          ),
          const Spacer(),
          _buildSearchField(),
          SizedBox(width: 24.w),
          if (actions != null) ...[
            ...actions!,
            SizedBox(width: 24.w),
          ] else ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 24.r),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 24.w),
          ],
          _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 300.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 10.h), // Adjust alignment
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 18.r,
      backgroundColor: AppColors.neonPurple,
      child: Icon(Icons.person, color: Colors.white, size: 20.sp),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_defaultHeight);
}
