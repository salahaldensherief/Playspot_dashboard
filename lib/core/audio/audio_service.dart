import 'package:audioplayers/audioplayers.dart';

abstract class AudioService {
  Future<void> playNotificationSound();
}

class AudioServiceImpl implements AudioService {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> playNotificationSound() async {
    try {
      // Check if we are on web and handle potential missing assets gracefully
      await _player.play(AssetSource('audio/new_booking.mp3'));
    } catch (e) {
      // Audio might fail in dev environments without the actual file
    }
  }
}
