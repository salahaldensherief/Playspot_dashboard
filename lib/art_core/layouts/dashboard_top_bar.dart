import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'top_bar/top_bar_audio_toggle.dart';
import 'top_bar/top_bar_lounge_status_toggle.dart';
import 'top_bar/top_bar_notification_bell.dart';
import 'top_bar/top_bar_shift_indicator.dart';
import 'top_bar/top_bar_user_profile.dart';

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

          const SizedBox(width: 8),

          // Right Side: Actions & User Info
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (actions != null) ...[
                    ...actions!,
                    const SizedBox(width: 12),
                  ] else ...[
                    const TopBarShiftIndicator(),
                    const SizedBox(width: 8),
                    const TopBarLoungeStatusToggle(),
                    const SizedBox(width: 8),
                    const TopBarAudioToggle(),
                    const SizedBox(width: 8),
                    const TopBarNotificationBell(),
                    const SizedBox(width: 12),
                  ],
                  const TopBarUserProfile(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_defaultHeight);
}
