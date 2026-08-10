import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract class AudioService {
  Future<void> playNotificationSound();
}

class AudioServiceImpl implements AudioService {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> playNotificationSound() async {
    try {
      // Audio file might not exist in all environments
      await _player.play(AssetSource('audio/new_booking.mp3'));
    } catch (e) {
      debugPrint('Audio playback failed: $e');
    }
  }
}
