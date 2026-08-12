import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract class AudioService {
  Future<void> playNotificationSound();
}

class AudioServiceImpl implements AudioService {
  final AudioPlayer _player = AudioPlayer();

  AudioServiceImpl() {
    if (kIsWeb) {
      // On web, we need to ensure the audio context is initialized after user interaction
      // This is a common requirement for web browsers to allow audio playback.
    }
  }

  @override
  Future<void> playNotificationSound() async {
    try {
      // Use setSource first to catch specific loading errors on Web
      await _player.setSource(AssetSource('audio/new_booking.mp3'));
      await _player.resume();
    } catch (e) {
      // On web, failure often happens because of browser security policies 
      // or unsupported audio formats in specific browsers.
      debugPrint('Audio playback info: Notice - Audio could not be played. This is expected on some browsers before user interaction. Error: $e');
    }
  }
}
