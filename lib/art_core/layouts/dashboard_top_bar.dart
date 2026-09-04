import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_state.dart';
import '../app_strings.dart';
import '../theme/app_colors.dart';

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showMenuButton;

  const DashboardTopBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showMenuButton = false,
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
          if (showMenuButton) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            SizedBox(width: 8.w),
          ],
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
            SizedBox(width: 16.w),
          ] else ...[
            _buildLoungeStatusToggle(context),
            SizedBox(width: 16.w),
            _buildAudioMuteToggle(context),
            SizedBox(width: 16.w),
            _buildNotificationIcon(context),
            SizedBox(width: 16.w),
          ],
          _buildUserInfo(),
        ],
      ),
    );
  }

  Widget _buildLoungeStatusToggle(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) =>
          prev.user != curr.user || prev.userLounge != curr.userLounge,
      builder: (context, loginState) {
        final user = loginState.user;
        final loungeId = user?.loungeId;
        if (user == null ||
            !user.canToggleLoungeStatus ||
            loungeId == null ||
            loungeId.isEmpty) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<LoungeCubit, LoungeState>(
          buildWhen: (prev, curr) => prev.lounges != curr.lounges,
          builder: (context, loungeState) {
            Lounge? currentLounge;
            if (loungeState.lounges.isNotEmpty) {
              final found =
                  loungeState.lounges.where((l) => l.id == loungeId).toList();
              if (found.isNotEmpty) currentLounge = found.first;
            }

            final isOpen =
                currentLounge?.isOpen ?? (loginState.userLounge?.isOpen ?? true);
            final bool isMobile = MediaQuery.sizeOf(context).width < 600;
            final color = isOpen ? AppColors.success : AppColors.danger;

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8.w : 12.w,
                vertical: 2.h,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isMobile) SizedBox(width: 8.w),
                  if (!isMobile)
                    Text(
                      isOpen ? AppStrings.loungeIsOpen : AppStrings.loungeIsClosed,
                      style: TextStyle(
                        color: color,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(width: 4.w),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: isOpen,
                      activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.success,
                      inactiveThumbColor: AppColors.danger,
                      inactiveTrackColor: AppColors.danger.withValues(alpha: 0.3),
                      onChanged: (val) {
                        context.read<LoungeCubit>().toggleLoungeStatus(loungeId, val);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAudioMuteToggle(BuildContext context) {
    final audioService = sl<AudioService>();
    return ListenableBuilder(
      listenable: audioService,
      builder: (context, _) {
        final isMuted = audioService.isMuted;
        return Tooltip(
          message: isMuted ? 'Unmute Alerts' : 'Mute Alert Sound',
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: () => audioService.toggleMute(),
            child: Padding(
              padding: EdgeInsets.all(4.r),
              child: Icon(
                isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: isMuted ? AppColors.textMuted : AppColors.neonBlue,
                size: 22.r,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      buildWhen: (prev, curr) => prev.bookings != curr.bookings,
      builder: (context, state) {
        final pendingCount = state.bookings
            .where((b) => b.status == BookingStatus.pending)
            .length;

        return Tooltip(
          message: pendingCount > 0
              ? '$pendingCount ${AppStrings.pendingRequests}'
              : AppStrings.noNotifications,
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: () => context.go(RouterKeys.loungeAdminLiveOps),
            child: Padding(
              padding: EdgeInsets.all(4.r),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textSecondary,
                    size: 24.r,
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16.r,
                          minHeight: 16.r,
                        ),
                        child: Text(
                          '$pendingCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo() {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) => prev.user != curr.user,
      builder: (context, state) {
        final user = state.user;
        if (user == null) return _buildDefaultAvatar();

        final bool isMobile = MediaQuery.sizeOf(context).width < 600;

        return Container(
          constraints: BoxConstraints(maxWidth: isMobile ? 50.w : 200.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isMobile)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
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
                ),
              if (!isMobile) SizedBox(width: 12.w),
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
      backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
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
