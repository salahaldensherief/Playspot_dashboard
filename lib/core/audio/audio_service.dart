import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract class AudioService extends ChangeNotifier {
  bool get isMuted;
  void toggleMute();
  void setMuted(bool muted);
  Future<void> playNotificationSound();
}

class AudioServiceImpl extends ChangeNotifier implements AudioService {
  late final AudioPlayer _player;
  bool _isMuted = false;

  AudioServiceImpl() {
    _player = AudioPlayer();
    _initPlayer();
  }

  void _initPlayer() {
    try {
      _player.setPlayerMode(PlayerMode.mediaPlayer);
      _player.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('AudioPlayer init error: $e');
    }
  }

  @override
  bool get isMuted => _isMuted;

  @override
  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  @override
  void setMuted(bool muted) {
    if (_isMuted != muted) {
      _isMuted = muted;
      notifyListeners();
    }
  }

  @override
  Future<void> playNotificationSound() async {
    if (_isMuted) return;

    try {
      await _player.stop();
      if (kIsWeb) {
        try {
          await _player.play(AssetSource('audio/notification.wav'));
        } catch (_) {
          await _player.play(UrlSource('assets/assets/audio/notification.wav'));
        }
      } else {
        await _player.play(AssetSource('audio/notification.wav'));
      }
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }
}
