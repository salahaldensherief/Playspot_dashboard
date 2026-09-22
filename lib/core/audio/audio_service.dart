import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AudioService extends ChangeNotifier {
  bool get isMuted;
  void toggleMute();
  void setMuted(bool muted);
  Future<void> playNotificationSound();
  Future<void> playUrgentAlertSound();
  Future<void> stopUrgentAlertSound();
}

class AudioServiceImpl extends ChangeNotifier implements AudioService {
  static const String _prefMuteKey = 'audio_alerts_muted';
  
  late final AudioPlayer _player;
  late final AudioPlayer _urgentPlayer;
  bool _isMuted = false;
  bool _isUrgentPlaying = false;

  AudioServiceImpl() {
    _player = AudioPlayer();
    _urgentPlayer = AudioPlayer();
    _initPlayer();
    _loadMutePreference();
  }

  void _initPlayer() {
    try {
      _player.setPlayerMode(PlayerMode.mediaPlayer);
      _player.setReleaseMode(ReleaseMode.stop);
      
      _urgentPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      _urgentPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint('AudioPlayer init error: $e');
    }
  }

  Future<void> _loadMutePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool(_prefMuteKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load audio preference: $e');
    }
  }

  Future<void> _saveMutePreference(bool muted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefMuteKey, muted);
    } catch (e) {
      debugPrint('Failed to save audio preference: $e');
    }
  }

  @override
  bool get isMuted => _isMuted;

  @override
  void toggleMute() {
    setMuted(!_isMuted);
  }

  @override
  void setMuted(bool muted) {
    if (_isMuted != muted) {
      _isMuted = muted;
      _saveMutePreference(muted);
      if (_isMuted) {
        stopUrgentAlertSound();
      }
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

  @override
  Future<void> playUrgentAlertSound() async {
    if (_isMuted || _isUrgentPlaying) return;

    try {
      _isUrgentPlaying = true;
      await _urgentPlayer.stop();
      if (kIsWeb) {
        try {
          await _urgentPlayer.play(AssetSource('audio/notification.wav'));
        } catch (_) {
          await _urgentPlayer.play(UrlSource('assets/assets/audio/notification.wav'));
        }
      } else {
        await _urgentPlayer.play(AssetSource('audio/notification.wav'));
      }
    } catch (e) {
      _isUrgentPlaying = false;
      debugPrint('Urgent audio playback error: $e');
    }
  }

  @override
  Future<void> stopUrgentAlertSound() async {
    if (!_isUrgentPlaying) return;
    try {
      _isUrgentPlaying = false;
      await _urgentPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping urgent audio: $e');
    }
  }
}
