import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/router/router_keys.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';

import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_state.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_cubit.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/shift_state.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import '../app_strings.dart';
import '../theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_cached_image.dart';

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

  static double get _defaultHeight => 64.0;

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return Container(
      height: _defaultHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Title & Menu/Leading
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showMenuButton) ...[
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  const SizedBox(width: 8),
                ],
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 16),
                ],
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right Side: Actions & User Info
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (actions != null) ...[
                ...actions!,
                const SizedBox(width: 16),
              ] else ...[
                _buildShiftStatusIndicator(context),
                const SizedBox(width: 12),
                _buildLoungeStatusToggle(context),
                const SizedBox(width: 12),
                _buildAudioMuteToggle(context),
                const SizedBox(width: 12),
                _buildNotificationIcon(context),
                const SizedBox(width: 16),
              ],
              _buildUserInfo(),
            ],
          ),
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
            user.isSuperAdmin ||
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
                horizontal: isMobile ? 8 : 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isMobile) const SizedBox(width: 8),
                  if (!isMobile)
                    Text(
                      isOpen ? AppStrings.loungeIsOpen : AppStrings.loungeIsClosed,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: isOpen,
                      activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.success,
                      inactiveThumbColor: AppColors.danger,
                      inactiveTrackColor: AppColors.danger.withValues(alpha: 0.3),
                      onChanged: (val) async {
                        await context.read<LoungeCubit>().toggleLoungeStatus(loungeId, val);
                        if (context.mounted) {
                          context.read<LoginCubit>().refreshUserLounge(loungeId);
                        }
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
            borderRadius: BorderRadius.circular(20),
            onTap: () => audioService.toggleMute(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: isMuted ? AppColors.textMuted : AppColors.neonBlue,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShiftStatusIndicator(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    if (user == null || user.isSuperAdmin) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<ShiftCubit, ShiftState>(
      buildWhen: (prev, curr) => prev.activeShift != curr.activeShift || prev.status != curr.status,
      builder: (context, shiftState) {
        final isActive = shiftState.activeShift != null;
        final bool isMobile = MediaQuery.sizeOf(context).width < 600;
        final color = isActive ? AppColors.success : AppColors.warning;

        return Tooltip(
          message: isActive ? AppStrings.shiftActive : AppStrings.noActiveShift,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isMobile) const SizedBox(width: 8),
                if (!isMobile)
                  Text(
                    isActive ? AppStrings.shiftActive : AppStrings.noActiveShift,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    if (user == null || user.isSuperAdmin) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<ClientRequestsCubit, ClientRequestsState>(
      buildWhen: (prev, curr) => prev.requests != curr.requests || prev.status != curr.status,
      builder: (context, state) {
        final pendingCount = state.requests.where((r) => !r.isAttended).length;

        return Tooltip(
          message: pendingCount > 0
              ? '$pendingCount ${AppStrings.pendingRequests}'
              : AppStrings.noNotifications,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.go(RouterKeys.loungeAdminLiveOps),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$pendingCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
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

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isMobile) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.isSuperAdmin 
                      ? AppStrings.superAdmin 
                      : (user.isLoungeOwner 
                          ? AppStrings.loungeOwnerLabel 
                          : (user.isCashier ? AppStrings.cashierLabel : AppStrings.loungeManager)),
                    style: const TextStyle(
                      color: AppColors.neonPurple,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
            _buildAvatar(user.avatarUrl),
          ],
        );
      },
    );
  }

  Widget _buildAvatar(String? url) {
    final bool hasAvatar = url != null && url.trim().isNotEmpty;
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
      backgroundImage: hasAvatar ? AppCachedImage.provider(url) : null,
      child: !hasAvatar 
        ? const Icon(Icons.person, color: AppColors.neonPurple, size: 20)
        : null,
    );
  }

  Widget _buildDefaultAvatar() {
    return const CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.neonPurple,
      child: Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_defaultHeight);
}
