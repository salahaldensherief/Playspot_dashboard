import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract class AudioService {
  Future<void> playNotificationSound();
}

class AudioServiceImpl implements AudioService {
  late final AudioPlayer _player;

  AudioServiceImpl() {
    _player = AudioPlayer();
    _initPlayer();
  }

  void _initPlayer() {
    _player.setPlayerMode(PlayerMode.mediaPlayer);
    _player.setReleaseMode(ReleaseMode.stop);
  }

  @override
  Future<void> playNotificationSound() async {
    try {
      await _player.stop();
      if (kIsWeb) {
        try {
          await _player.play(UrlSource('assets/assets/audio/notification.wav'));
        } catch (_) {
          await _player.play(AssetSource('audio/notification.wav'));
        }
      } else {
        await _player.play(AssetSource('audio/notification.wav'));
      }
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }
}