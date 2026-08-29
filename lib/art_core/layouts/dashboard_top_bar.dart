import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/close_shift_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import '../app_strings.dart';
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
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          const Spacer(),
          if (actions != null) ...[
            ...actions!,
            SizedBox(width: 24.w),
          ] else ...[
            _buildNotificationIcon(),
            SizedBox(width: 24.w),
          ],
          _buildUserInfo(),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
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
    );
  }

  Widget _buildUserInfo() {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final user = state.user;
        if (user == null) return _buildDefaultAvatar();

        return Container(
          constraints: BoxConstraints(maxWidth: 200.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      user.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.isSuperAdmin 
                        ? AppStrings.superAdmin 
                        : (user.isLoungeOwner 
                            ? AppStrings.loungeOwnerLabel 
                            : (user.isCashier ? AppStrings.cashierLabel : AppStrings.loungeManager)),
                      style: TextStyle(
                        color: AppColors.neonPurple,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              _buildAvatar(user.avatarUrl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? url) {
    return CircleAvatar(
      radius: 18.r,
      backgroundColor: AppColors.neonPurple.withOpacity(0.2),
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null 
        ? Icon(Icons.person, color: AppColors.neonPurple, size: 20.sp)
        : null,
    );
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: 18.r,
      backgroundColor: AppColors.neonPurple,
      child: Icon(Icons.person, color: Colors.white, size: 20.sp),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_defaultHeight);
}
