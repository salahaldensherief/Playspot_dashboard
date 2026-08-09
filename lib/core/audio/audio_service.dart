import 'package:audioplayers/audioplayers.dart';

abstract class AudioService {
  Future<void> playNotificationSound();
}

class AudioServiceImpl implements AudioService {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> playNotificationSound() async {
    try {
      await _player.play(AssetSource('audio/new_booking.mp3'));
    } catch (e) {
      // Handle or log audio play failure
      print('Audio play error: $e');
    }
  }
}
