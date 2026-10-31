import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/core/di/di.dart';

class TopBarAudioToggle extends StatelessWidget {
  const TopBarAudioToggle({super.key});

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final audioService = sl<AudioService>();
    return ListenableBuilder(
      listenable: audioService,
      builder: (context, _) {
        final isMuted = audioService.isMuted;
        return Tooltip(
          message: isMuted
              ? 'enable_notification_sounds'.tr()
              : 'mute_notification_sounds'.tr(),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => audioService.toggleMute(),
            onLongPress: () {
              if (!isMuted) {
                audioService.playNotificationSound();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('preview_notification_sound'.tr()),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
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
}
